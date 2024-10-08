import os
import random
import time

from celery import Celery, Task

celery = Celery(
    "tasks",
    broker=os.getenv("CELERY_BROKER_URL", "redis://localhost:6379"),
    backend=os.getenv("CELERY_RESULT_BACKEND", "redis://localhost:6379"),
)
celery.conf.broker_connection_retry_on_startup = True


@celery.task(bind=True, name="fastapi_celery.worker.analyze_data")
def analyze_data(self: Task, data_size: int):
    total_steps = 5
    for step in range(total_steps):
        # 各ステップで進捗を更新
        self.update_state(
            state="PROGRESS", meta={"current": step + 1, "total": total_steps}
        )
        # 重い処理をシミュレート
        time.sleep(random.randint(3, 7))
    return {
        "analyzed_items": data_size,
        "anomalies_detected": random.randint(0, data_size // 10),
        "processing_time": random.uniform(15, 30),
    }
