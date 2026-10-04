# EduCore Parent Portal

GitHub-ready parent portal for the EduCore School Management System.

## Upload to GitHub
1. Extract this ZIP on your computer.
2. Open the extracted folder. You should see `index.html`, `package.json`, `src`, `public`, and `supabase` directly inside it.
3. Create/open a GitHub repository.
4. Upload the **contents of this folder**, not the ZIP and not another outer folder.
5. Commit to the `main` branch.
6. GitHub Actions will build and deploy the site to GitHub Pages.

## Supabase
Create `.env.local` for local development using the values in `.env.example`.
Apply `supabase/migrations/001_parent_portal.sql` to the same Supabase project used by EduCore.

Never put a Supabase service-role key in this project. The browser may use the public anon key only when RLS is configured correctly.

## GitHub Pages
In GitHub open **Settings → Pages → Build and deployment → Source** and select **GitHub Actions**. Push to `main`; the included workflow builds and deploys the site.
