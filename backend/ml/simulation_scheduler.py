import os
from apscheduler.schedulers.background import BackgroundScheduler
from ml import simulator

_scheduler = BackgroundScheduler(timezone="UTC")


def start_scheduler():
    if _scheduler.running:
        return
    seconds = max(1, int(os.getenv("SIM_INTERVAL_SECONDS", "5")))
    _scheduler.add_job(
        simulator.tick,
        trigger="interval",
        seconds=seconds,
        id="sepsis-test-simulation",
        replace_existing=True,
        max_instances=1,
        coalesce=True,
    )
    _scheduler.start()
    print(f"[simulation] horloge activée : 1 heure de données toutes les {seconds} secondes")


def stop_scheduler():
    if _scheduler.running:
        _scheduler.shutdown(wait=False)


def scheduler_running() -> bool:
    return _scheduler.running
