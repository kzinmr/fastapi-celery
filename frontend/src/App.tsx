import React, { useState } from "react";
import {
  QueryClient,
  QueryClientProvider,
  useMutation,
  useQuery,
} from "@tanstack/react-query";
import { z } from "zod";

const queryClient = new QueryClient();

const ANALYSIS_TIMEOUT_SECONDS = 60;

const AnalysisFormSchema = z.object({
  data_size: z.number().int().positive().max(10000),
});

const AnalysisTaskSchema = z.object({
  task_id: z.string().uuid(),
});

const AnalysisResultSchema = z.object({
  state: z.enum(["PENDING", "PROGRESS", "SUCCESS", "FAILURE"]),
  current: z.number().int().optional(),
  total: z.number().int().optional(),
  status: z.string().optional(),
  result: z
    .object({
      analyzed_items: z.number().int(),
      anomalies_detected: z.number().int(),
      processing_time: z.number(),
    })
    .nullable()
    .optional(),
});

type AnalysisFormData = z.infer<typeof AnalysisFormSchema>;
type AnalysisTask = z.infer<typeof AnalysisTaskSchema>;
type AnalysisResult = z.infer<typeof AnalysisResultSchema>;

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <div className="container mx-auto p-4">
        <h2 className="text-2xl font-bold mb-4">Celery Example</h2>
        <p className="mb-4">
          Execute background tasks with Celery. Submits tasks and shows results
          using React, TypeScript, TanStack Query, and Zod validation.
        </p>
        <hr className="mb-4" />
        <AnalyzeDataForm />
      </div>
    </QueryClientProvider>
  );
}

function AnalyzeDataForm() {
  const [taskId, setTaskId] = useState<string | null>(() => {
    // Persistent state across page reloads
    return localStorage.getItem("analysisTaskId");
  });
  const [formData, setFormData] = useState<AnalysisFormData>({
    data_size: 1000,
  });
  const [formErrors, setFormErrors] = useState<z.ZodError | null>(null);

  const analyzeMutation = useMutation<AnalysisTask, Error, AnalysisFormData>({
    mutationFn: async (data) => {
      const response = await fetch("/api/tasks/analyze", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(data),
      });
      if (!response.ok) {
        if (response.status === 422) {
          const errorData = (await response.json()) as Record<string, unknown>;
          throw new Error(JSON.stringify(errorData) || "Validation error");
        }
        throw new Error("Network response was not ok");
      }
      const responseData = (await response.json()) as Record<string, unknown>;
      try {
        return AnalysisTaskSchema.parse(responseData);
      } catch (parseError) {
        console.error("Failed to parse response in mutation:", parseError);
        throw new Error("Invalid response format");
      }
    },
    onSuccess: (data) => {
      setTaskId(data.task_id);
      localStorage.setItem("analysisTaskId", data.task_id);
    },
    onError: (error) => {
      console.error("Analysis task error:", error);
      // Optionally, you can set an error state here to display to the user
    },
  });

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    try {
      const validatedData = AnalysisFormSchema.parse(formData);
      setFormErrors(null);
      analyzeMutation.mutate(validatedData);
    } catch (error) {
      if (error instanceof z.ZodError) {
        setFormErrors(error);
      }
    }
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: parseInt(value, 10) }));
  };

  return (
    <div>
      <h4 className="text-xl font-semibold mb-2">Analyze Data</h4>
      <p className="mb-4">
        Start a heavy data analysis task and poll for the result.
      </p>
      <form onSubmit={handleSubmit} className="mb-4">
        <div className="mb-2">
          <label className="block">
            Data Size:
            <input
              type="number"
              name="data_size"
              value={formData.data_size}
              onChange={handleInputChange}
              className="ml-2 border rounded px-2 py-1"
            />
          </label>
          {formErrors?.errors.find((e) => e.path[0] === "data_size") && (
            <p className="text-red-500 text-sm">
              Data size must be a positive integer not exceeding 10000
            </p>
          )}
        </div>
        <button
          type="submit"
          className="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
          disabled={analyzeMutation.isPending}
        >
          {analyzeMutation.isPending ? "Submitting..." : "Start Analysis"}
        </button>
      </form>
      {taskId && (
        <>
          <AnalysisResult taskId={taskId} timeout={ANALYSIS_TIMEOUT_SECONDS} />
          <button
            onClick={() => {
              setTaskId(null);
              localStorage.removeItem("analysisTaskId");
            }}
            className="mt-4 bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600"
          >
            Clear Result
          </button>
        </>
      )}
    </div>
  );
}

interface AnalysisResultProps {
  taskId: string;
  timeout: number;
}

function AnalysisResult({ taskId, timeout }: AnalysisResultProps) {
  const { data, error, isLoading } = useQuery<AnalysisResult, Error>({
    queryKey: ["analysisResult", taskId],
    queryFn: async () => {
      const response = await fetch(`/api/tasks/result/${taskId}`);
      if (!response.ok) {
        throw new Error("Network response was not ok");
      }
      const responseData = (await response.json()) as Record<string, unknown>;
      try {
        return AnalysisResultSchema.parse(responseData);
      } catch (parseError) {
        console.error("Failed to parse response in query:", parseError);
        throw new Error("Invalid response format");
      }
    },
    refetchInterval: (query) => {
      const data = query.state.data;
      if (data?.state === "SUCCESS" || data?.state === "FAILURE") {
        return false;
      }
      return Math.min(500 * Math.pow(1.5, data?.current || 0), 5000);
    },
    retry: true,
    retryDelay: 1000,
    staleTime: Infinity,
    gcTime: timeout,
  });

  if (isLoading) return <p>Loading...</p>;
  if (error) return <p>Error: {error.message}</p>;
  if (!data) return null;

  if (data.state !== "SUCCESS") {
    return (
      <p>
        Analyzing... Progress: {data.current}/{data.total}
      </p>
    );
  }

  return (
    <p>
      Analysis complete! Analyzed {data.result?.analyzed_items} items, detected{" "}
      {data.result?.anomalies_detected} anomalies. Processing time:{" "}
      {data.result?.processing_time.toFixed(2)} seconds.
    </p>
  );
}

export default App;
