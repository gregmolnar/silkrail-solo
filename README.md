# Silkrail Solo

A self-hosted, single-tenant Rails storefront for selling digital products. It keeps the Silkrail product/release/discount workflow, but removes multi-tenancy and Stripe Connect: every payment goes directly to the Stripe account configured by the operator.

## Features

- Public storefront and product pages
- Stripe-hosted Checkout with optional automatic Stripe Tax and invoices
- Signed Stripe webhooks with idempotent fulfillment
- Private, unguessable buyer download pages with admin token revocation and regeneration
- Products, Lexxy rich-text descriptions, cover images, releases, and file uploads
- General storefront CSS plus per-product page CSS customization
- Rich-text privacy, terms, refund, and seller-information pages
- Self-hosted text and video testimonials with moderation and storefront display
- Expiring and redemption-limited percentage discounts
- Gumroad purchase CSV import with original dates and prices
- Manual purchase entry with optional receipt delivery
- Owner dashboard, sales list, and store settings
- Receipt email with a permanent access link
- Optional owner email notification for every new purchase
- Customer accounts with password-reset email flow and a purchase library
- IP-based rate limiting for password-reset requests and file downloads
- Queued product-update emails to all unique buyers of a product

## Local setup

Requirements: Ruby 3.4, PostgreSQL, and Stripe CLI.

```sh
cp .env.example .env # export these variables or use your preferred env loader
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/dev
```

The default seeded login is `owner@example.com` / `change-me-now-123`. Change it immediately, or set `ADMIN_EMAIL` and `ADMIN_PASSWORD` before seeding.

### Local CI and signoff

Authenticate GitHub CLI and install the signoff extension once:

```sh
gh auth login
gh extension install basecamp/gh-signoff
```

Make sure the repository has a GitHub remote, then run:

```sh
bin/ci
```

A successful run executes `gh signoff` and publishes a green commit status. Failed checks are not signed off.

Set `STRIPE_SECRET_KEY`. For local webhooks:

```sh
stripe listen --forward-to localhost:3000/webhooks/stripe
```

Copy the printed `whsec_...` value to `STRIPE_WEBHOOK_SECRET`. Subscribe the production Stripe webhook to `checkout.session.completed` at `https://YOUR_HOST/webhooks/stripe`.

Stripe Tax is disabled by default. Enable it under **Admin → Settings → Taxes** when the store needs automatic sales-tax or VAT calculation. You can keep displayed prices tax-inclusive or add tax at checkout. When enabled, Checkout requires a billing address, offers business tax-ID collection, calculates tax, and creates a Stripe invoice. Configure the business origin, product tax code, and required tax registrations in Stripe before enabling it. Stripe calculates tax but the operator remains responsible for registrations, filing, and remittance.

## Email in development

Development emails are written to `tmp/mails` instead of being sent. Password resets, receipts, and product announcements use Active Job. In production, configure the `MAIL_FROM` and `SMTP_*` variables from `.env.example`; Solid Queue runs through Puma by default.

Customers can sign in or request a password at `/account/session/new`. To send a product announcement, open the product in the admin and choose **Email customers**. The message is queued once for each unique buyer email.

Buyers can leave a testimonial from their purchase download page. Submissions enter the moderation dashboard at `/testimonials`; only approved testimonials with public consent appear on product pages. NPS and automatic prompts are intentionally disabled, so the widget opens only after a buyer clicks **Leave a review**.

## Deployment

Kamal is fully environment-driven. Start from the root environment template:

```sh
cp .env.example .env
$EDITOR .env
set -a
source .env
set +a
bin/kamal setup
```

`.env` is ignored by Git. `config/deploy.yml` reads server hosts, image and registry details, proxy settings, runtime tuning, SMTP configuration, and storage volume names from those variables. Comma-separate `KAMAL_WEB_HOSTS` to deploy to multiple web hosts. The default registry is an unauthenticated local registry at `localhost:5555`; set the registry username/password variables when using GHCR or another authenticated registry.

With `SOLID_QUEUE_IN_PUMA=true`, the web container runs Solid Queue. Set it to `false` to have Kamal deploy a separate `job` role running `bin/jobs`. `KAMAL_JOB_HOSTS` controls its hosts and falls back to `KAMAL_WEB_HOSTS` when omitted or blank.

The Docker entrypoint runs `bin/rails db:prepare` before each new web container starts. Application, Solid Cache, and Solid Queue tables share the primary PostgreSQL database and are installed through normal migrations. To run migrations manually against the primary deployed container, use `bin/kamal migrate`.

Provide `DATABASE_URL`, `RAILS_MASTER_KEY`, the Stripe secrets, SMTP credentials, and the `S3_*` settings. Active Storage uses the private `s3` service by default and supports AWS S3, Cloudflare R2, DigitalOcean Spaces, Backblaze B2, MinIO, and similar providers. Set `S3_FORCE_PATH_STYLE` as required by the provider. Release files upload directly from the browser to storage, so the bucket CORS policy must allow `PUT` requests from the storefront origin. To use the mounted `/rails/storage` volume instead, set `ACTIVE_STORAGE_SERVICE=local` and include that volume in backups.

Run `bin/kamal app exec "bin/rails db:prepare db:seed"` once, then sign in at `/session/new`.

Never put Stripe keys in the database or source tree. Rotate webhook secrets and owner credentials when moving an installation.
