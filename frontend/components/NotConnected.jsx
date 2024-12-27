import { Card, CardHeader, CardTitle, CardDescription } from "./ui/card";

const NotConnected = () => {
  return (
    <div className="flex items-center justify-center h-[60vh]">
      <Card className="w-[400px] rounded-3xl bg-gradient-brand-light border shadow-md">
        <CardHeader>
          <CardTitle>Connect Wallet</CardTitle>
          <CardDescription>
            Connect your wallet to view your dashboard
          </CardDescription>
        </CardHeader>
      </Card>
    </div>
  );
};

export default NotConnected;
