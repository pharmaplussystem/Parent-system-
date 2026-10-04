import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { VitePWA } from 'vite-plugin-pwa';

export default defineConfig({
  base: './',
  plugins: [react(), VitePWA({
    registerType: 'autoUpdate',
    includeAssets: ['favicon.svg'],
    manifest: {
      name: 'EduCore Parent Portal', short_name: 'EduCore Parent', start_url: './', display: 'standalone',
      background_color: '#f8fafc', theme_color: '#0f766e', description: 'Secure parent portal for EduCore School Management System',
      icons: [{src:'pwa-192.svg',sizes:'192x192',type:'image/svg+xml'},{src:'pwa-512.svg',sizes:'512x512',type:'image/svg+xml'}]
    }, workbox: { navigateFallback: 'index.html' }
  })]
});
