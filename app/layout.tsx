import "./globals.css";
export const metadata = { title: "MarinaOS", description: "Secure marina operations" };
export default function Layout({ children }: Readonly<{ children: React.ReactNode }>) { return <html lang="en"><body>{children}</body></html>; }
