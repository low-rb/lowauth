# LowAuth

Logins for [Raindeer](https://github.com/raindeer-rb/raindeer). LowAuth hashes passwords with Argon2 and keeps sessions in a database table. It guards nodes so only users with a role can call them.

## Setup

LowAuth uses a Sequel database with a `users` table and a `sessions` table:

```ruby
create_table(:sessions) do
  primary_key :id
  String :token_digest, null: false, unique: true
  foreign_key :user_id, :users, null: false, on_delete: :cascade
  String :ip
  String :user_agent, text: true
  DateTime :created_at, null: false
  DateTime :expires_at, null: false
end

alter_table(:users) { add_column :password_hash, String }
```

Configure it when your app boots, and give your nodes its guard and helpers:

```ruby
require 'lowauth'

LowAuth.configure do |config|
  config.database = DB
  config.login_columns = %i[username email]
  config.roles = { admin: ->(user) { user[:role] == 'admin' } }
  config.can_log_in = ->(user) { !user[:blocked] }
end

LowNode.extend(LowAuth::Guard)
LowNode.include(LowAuth::NodeHelpers)
```

## Logging in

```ruby
class LoginNode < LowNode
  observe '/login'

  def receive(event:)
    return unless LowAuth.same_origin?(event)

    form = event.body
    user = LowAuth::Passwords.authenticate(form[:login], form[:password])
    return LoginFailedNode.render(event:) unless user

    log_in(user, event:)
    redirect('/')
  end
end
```

`log_in` makes a session and sets its cookie. `log_out(event:)` ends it, and `current_user(event)` is the user who's logged in, or nil.

The cookie holds a random token and the `sessions` table holds only its SHA-256, so a leaked table can't log anyone in. Sessions last 30 days, which `config.session_days` changes.

## Guards

`requires :admin` lets only users with the `admin` role call a node's actions, and `requires` lets in any logged in user:

```ruby
class InvitesNode < LowNode
  observe '/admin/invites'

  requires :admin
end
```

Anyone else gets nothing, so the router moves on and responds with a 404. Actions that change things, like `receive` and `post`, also need the form's Origin header to be this site.

## Passwords from another site

Users who came from another site can log in with their old password hashes. Tell LowAuth how to check one, and their password is rehashed with Argon2 the first time they log in:

```ruby
config.legacy_password = ->(user, password) { DrupalPassword.matches?(password, user[:drupal_password_hash]) }
```

## Guessing passwords

`LowAuth::LoginLimit` stops a login after 10 failures in 15 minutes for a key, like the login name:

```ruby
return TooManyAttemptsNode.render(event:) unless LowAuth::LoginLimit.allowed?(login)

LowAuth::LoginLimit.failed(login) unless user
```

It's kept in memory, so it's per process.
