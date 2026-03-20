import useData from "@/hooks/useData";

const Log = () => {
  const { logs } = useData();

  return (
    <div className="flex flex-col gap-0.5 p-1 w-full h-full overflow-auto">
      {logs.map((log, i) => (
        <div key={i} className="whitespace-pre-wrap">
          <span className="text-sm text-white/25 whitespace-nowrap float-left mr-1">
            [{new Date(log.created_at).toLocaleString()}]
          </span>
          <h1 className="text-sm text-white/50">{log.log_message}</h1>
        </div>
      ))}
    </div>
  );
};

export default Log;
