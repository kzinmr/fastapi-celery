from celery.result import AsyncResult
from fastapi import FastAPI, Form
from fastapi.responses import HTMLResponse

from fastapi_celery.worker import analyze_data

app = FastAPI()


@app.post("/tasks/analyze")
async def start_analysis(data_size: int = Form(...)):
    task = analyze_data.delay(data_size)
    return {"task_id": task.id}


@app.get("/tasks/result/{task_id}")
async def get_task_result(task_id: str):
    task = AsyncResult(task_id)
    if task.state == "PENDING":
        response = {
            "state": task.state,
            "current": 0,
            "total": 1,
            "status": "Pending...",
        }
    elif task.state != "FAILURE":
        response = {
            "state": task.state,
            "current": task.info.get("current", 0),
            "total": task.info.get("total", 1),
            "status": task.info.get("status", ""),
        }
        if task.state == "SUCCESS":
            response["result"] = task.result
    else:
        response = {
            "state": task.state,
            "current": 1,
            "total": 1,
            "status": str(task.info),
        }
    return response


@app.get("/", response_class=HTMLResponse)
async def index():
    return """
    <!doctype html>
    <html>
    <head>
      <meta charset=UTF-8>
      <title>Celery Example</title>
    </head>
    <body>
    <h2>Celery Example</h2>
    Execute background tasks with Celery. Submits tasks and shows results using JavaScript.

    <hr>
    <h4>Analyze Data</h4>
    <p>Start a heavy data analysis task and poll for the result.</p>
    <form id="analyze" method="post" action="/tasks/analyze">
      <label>Data Size: <input type="number" name="data_size" value="1000"></label><br>
      <label>Timeout (seconds): <input type="number" name="timeout" value="60"></label><br>
      <input type="submit" value="Start Analysis">
    </form>
    <p>Result: <span id="analyze-result"></span></p>

    <script>
      const taskForm = (formName, doPoll, report) => {
        document.forms[formName].addEventListener("submit", (event) => {
          event.preventDefault()
          const formData = new FormData(event.target)
          const timeout = formData.get('timeout') * 1000 || 60000 // デフォルトは60秒
          fetch(event.target.action, {
            method: "POST",
            body: formData
          })
            .then(response => response.json())
            .then(data => {
              report(null)

              let pollCount = 0
              const startTime = Date.now()
              const poll = () => {
                if (Date.now() - startTime > timeout) {
                  report({ error: "Timeout" })
                  return
                }

                fetch(`/tasks/result/${data["task_id"]}`)
                  .then(response => response.json())
                  .then(data => {
                    report(data)

                    if (data.state !== 'SUCCESS' && data.state !== 'FAILURE') {
                      setTimeout(poll, Math.min(500 * Math.pow(1.5, pollCount), 5000))
                      pollCount++
                    }
                  })
                  .catch(error => {
                    report({ error: "Network error" })
                  })
              }

              if (doPoll) {
                poll()
              }
            })
            .catch(error => {
              report({ error: "Failed to start task" })
            })
        })
      }

      taskForm("analyze", true, data => {
        const el = document.getElementById("analyze-result")
        if (data === null) {
          el.innerText = "Analysis submitted"
        } else if (data.error) {
          el.innerText = `Error: ${data.error}`
        } else if (data.state !== 'SUCCESS') {
          el.innerText = `Analyzing... Progress: ${data.current}/${data.total}`
        } else {
          el.innerText = `Analysis complete! Analyzed ${data.result.analyzed_items} items, ` +
                         `detected ${data.result.anomalies_detected} anomalies. ` +
                         `Processing time: ${data.result.processing_time.toFixed(2)} seconds.`
        }
      })
    </script>
    </body>
    </html>
    """
