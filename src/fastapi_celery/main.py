from celery.result import AsyncResult
from fastapi import FastAPI
from pydantic import BaseModel

from fastapi_celery.worker import analyze_data


class AnalysisRequest(BaseModel):
    data_size: int


class AnalysisTaskResponse(BaseModel):
    task_id: str


class TaskResultResponse(BaseModel):
    state: str
    current: int
    total: int
    status: str
    result: dict | None = None


app = FastAPI()


@app.post("/api/tasks/analyze", response_model=AnalysisTaskResponse)
async def start_analysis(request: AnalysisRequest):
    task = analyze_data.delay(request.data_size)
    return AnalysisTaskResponse(task_id=task.id)


@app.get("/api/tasks/result/{task_id}", response_model=TaskResultResponse)
async def get_task_result(task_id: str):
    task = AsyncResult(task_id)
    if task.state == "PENDING":
        return TaskResultResponse(
            state=task.state, current=0, total=1, status="Pending..."
        )
    elif task.state != "FAILURE":
        response = TaskResultResponse(
            state=task.state,
            current=task.info.get("current", 0),
            total=task.info.get("total", 1),
            status=task.info.get("status", ""),
        )
        if task.state == "SUCCESS":
            response.result = task.result
        return response
    else:
        return TaskResultResponse(
            state=task.state, current=1, total=1, status=str(task.info)
        )
