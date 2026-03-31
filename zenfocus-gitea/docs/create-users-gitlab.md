Create users
Tier: Free, Premium, Ultimate
Offering: GitLab Self-Managed, GitLab Dedicated
User accounts form the foundation of GitLab collaboration. Every person who needs access to your GitLab projects requires an account. User accounts control access permissions, track contributions, and maintain security across your instance.

You can create user accounts in GitLab in different ways:

Self-registration for teams who value autonomy
Admin-driven creation for controlled onboarding
Authentication integration for enterprise environments
Console access for automation and bulk operations
You can also use the users API endpoint to automatically create users.

Choose the right method based on your organization’s size, security requirements, and workflows.

Create a user on the sign-in page
By default, any user visiting your GitLab instance can register for an account. If you have previously disabled this setting, you must turn it back on.

Users can create their own accounts by either:

Selecting the Register now link on the sign-in page.
Navigating to your GitLab instance’s sign-up link (for example: <https://gitlab.example.com/users/sign_up>).
Create a user in the Admin area
Prerequisites:

You must be an administrator for the instance.
To create a user:

In the upper-right corner, select Admin.
Select Overview > Users.
Select New user.
In the Account section, enter the required account information.
Optional. In the Access section, configure any project limits or user type settings.
Select Create user.
GitLab sends an email to the user with a sign-in link, and the user must create a password when they first sign in. You can also directly set a password for the user.

Create a user with an authentication integration
GitLab can automatically create user accounts through authentication integrations. Users are created when they:

Are provisioned through SCIM in the identity provider.
Sign in for the first time with:
LDAP
Group SAML
An OmniAuth provider that has the setting allow_single_sign_on turned on
Create a user through the Rails console
Offering: GitLab Self-Managed
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

To create a user through the Rails console:

Start a Rails console session.

Run the command according to your GitLab version:

16.10 and earlier
16.11 through 17.6
17.7 and later
ruby
u = Users::CreateService.new(nil,
  username: 'lucas_user',
  email: '<lucas@zenfocus.com>',
  name: 'Lucas Mendes',
  password: '123password',
  password_confirmation: '123password',
  organization_id: Organizations::Organization.first.id,
  skip_confirmation: true
).execute
If you have disabled new sign-ups, you must run this command as an administrator. In the previous command, replace Users::CreateService.new(nil, with Users::CreateService.new(User.find_by(admin: true),
