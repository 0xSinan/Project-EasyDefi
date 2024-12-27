"use client";

import { useState, useEffect } from "react";
import { parseAbiItem, formatUnits } from "viem";
import { publicClient } from "../utils/client";
import { contractAddress } from "../constants/contract";
import { formatDistanceToNow } from "date-fns";
import Image from "next/image";

const Events = ({ type = "all", limit = 5, onRefetch }) => {
  const [events, setEvents] = useState([]);

  const getEvents = async () => {
    const depositEvents = await publicClient.getLogs({
      address: contractAddress,
      event: parseAbiItem(
        "event LiquidityAdded(address user, address tokenA, address tokenB, uint256 amountA, uint256 amountB, uint256 timestamp)"
      ),
      fromBlock: 0n,
      toBlock: "latest",
    });

    const withdrawEvents = await publicClient.getLogs({
      address: contractAddress,
      event: parseAbiItem(
        "event LiquidityRemoved(address user, address tokenA, address tokenB, uint256 amountA, uint256 amountB, uint256 timestamp)"
      ),
      fromBlock: 0n,
      toBlock: "latest",
    });

    let filteredEvents = [...depositEvents, ...withdrawEvents];

    if (type === "deposits") {
      filteredEvents = depositEvents;
    } else if (type === "withdrawals") {
      filteredEvents = withdrawEvents;
    }

    setEvents(
      filteredEvents
        .sort((a, b) => Number(b.args.timestamp) - Number(a.args.timestamp))
        .slice(0, limit)
    );

    if (onRefetch) {
      onRefetch();
    }
  };

  useEffect(() => {
    getEvents();
  }, [type, limit]);

  const EventCard = ({ event }) => (
    <div className="p-6 bg-white rounded-3xl border shadow-sm hover:shadow-md transition-shadow">
      <div className="flex justify-between items-start">
        <div className="flex items-start gap-4">
          <div
            className={`p-2 rounded-xl ${
              event.eventName === "LiquidityAdded"
                ? "bg-gradient-brand"
                : "bg-gradient-button"
            }`}
          >
            {event.eventName === "LiquidityAdded" ? "+" : "-"}
          </div>
          <div>
            <span className="font-semibold">
              {event.eventName === "LiquidityAdded" ? "Deposit" : "Withdraw"}
            </span>
            <p className="text-sm text-gray-500 mt-1">
              {formatDistanceToNow(Number(event.args.timestamp) * 1000, {
                addSuffix: true,
              })}
            </p>
          </div>
        </div>

        <div className="text-right">
          <div className="flex items-center gap-2 mb-1">
            <Image
              src="/images/tokens/alyra-logo.png"
              alt="ALY"
              width={20}
              height={20}
              className="rounded-full"
            />
            <p className="font-medium">
              {Number(formatUnits(event.args.amountA, 18)).toFixed(2)} ALY
            </p>
          </div>
          <div className="flex items-center gap-2">
            <Image
              src="/images/tokens/salyra-logo.png"
              alt="sALY"
              width={20}
              height={20}
              className="rounded-full"
            />
            <p className="font-medium">
              {Number(formatUnits(event.args.amountB, 18)).toFixed(2)} sALY
            </p>
          </div>
        </div>
      </div>
    </div>
  );

  return (
    <div className="space-y-3">
      {events.map((event, index) => (
        <EventCard key={`${event.transactionHash}-${index}`} event={event} />
      ))}
    </div>
  );
};

export default Events;
