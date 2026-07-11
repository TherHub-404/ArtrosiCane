/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  async rewrites() {
    return [
      { source: '/i/:token/:location', destination: '/i/index.html?t=:token&location=:location' },
      { source: '/i/:token', destination: '/i/index.html?t=:token' },
      { source: '/i', destination: '/i/index.html' },
      { source: '/privacy', destination: '/privacy/index.html' },
      { source: '/delete-account', destination: '/delete-account/index.html' },
    ];
  },
};

export default nextConfig;
