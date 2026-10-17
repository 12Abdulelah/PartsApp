# PartsApp — Automotive Spare Parts Marketplace

Flutter mobile application developed as a graduation project. PartsApp helps customers browse and compare automotive spare parts, place orders, and track their purchases. Vendors manage products and orders, while administrators review vendor registrations and complaints.

## Tech stack
- Flutter and Dart
- Node.js REST API (backend is not included in this repository)
- Supabase Storage

## Features
- Customer, vendor, and admin interfaces
- Product search, catalog, and inventory management
- Shopping cart, checkout, and order tracking
- Vendor registration and approval flow
- Reviews and complaints

## Setup
1. Install Flutter and run `flutter pub get`.
2. Copy `.env.example` to `.env`. Set your own `SUPABASE_URL` and a client-safe Supabase **anon/publishable key**. Never put a service-role or secret key in a mobile app.
3. Configure and start the separate Node.js API.
4. For Android emulator local debugging, the default API URL is `http://10.0.2.2:3000`.
5. To select a deployed API, use `flutter run --dart-define=API_BASE_URL=https://your-api.example.com`. Release builds require HTTPS.

## Security requirements before deployment
The server must authenticate requests and enforce roles and resource ownership. Never trust a client-provided `x-user-role`, user/store ID, price, or checkout total. Validate all orders and inventory changes server-side.

Commercial registration documents must live in a **private** Supabase Storage bucket named `store-docs`, with strict policies and server-generated short-lived signed URLs for authorized reviewers. Registration now passes a storage object path rather than a public URL. The separate backend may need adjustment to resolve the path.

Restrict uploaded file types/sizes and access; do not publish customer records, personal documents, credentials, `.env`, or production backups. Exposed historical credentials should be rotated.

## Project status
Educational / portfolio project. The backend and Supabase policies are not included here and have not been independently audited. No production security claim is made.
