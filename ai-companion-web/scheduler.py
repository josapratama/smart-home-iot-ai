"""
Scheduler Module - Scheduled actions & routines.
Allows AI to set timers and recurring tasks.
Now with JSON persistence so jobs survive restarts.
"""

import json
import uuid
from pathlib import Path
from datetime import datetime, timedelta, timezone
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from apscheduler.triggers.date import DateTrigger

JOBS_FILE = Path(__file__).parent / "scheduled_jobs.json"


class SchedulerModule:
    """Manages scheduled smart home actions with persistence."""

    def __init__(self, smart_home_controller):
        self.controller = smart_home_controller
        self.scheduler = AsyncIOScheduler()
        self.jobs: list[dict] = []
        self._load_jobs()
        self.scheduler.start()

    def _load_jobs(self):
        """Load persisted jobs and re-schedule recurring ones."""
        if not JOBS_FILE.exists():
            return
        try:
            with open(JOBS_FILE, "r") as f:
                saved = json.load(f)
        except (json.JSONDecodeError, IOError):
            return

        now = datetime.now(timezone.utc)
        for job in saved:
            if job["type"] == "recurring":
                # Re-schedule recurring jobs
                try:
                    parts = job["schedule"].split(" ")
                    hour, minute = int(parts[0].split(":")[0]), int(parts[0].split(":")[1])
                    days_str = parts[1].strip("()") if len(parts) > 1 else "mon-sun"
                    day_map = {"mon-sun": "*", "weekday": "mon-fri", "weekend": "sat,sun"}
                    day_of_week = day_map.get(days_str, days_str)

                    self.scheduler.add_job(
                        self._execute_action,
                        trigger=CronTrigger(hour=hour, minute=minute, day_of_week=day_of_week),
                        args=[job["target"], job["state"], job.get("reason", "")],
                        id=job["id"],
                    )
                    self.jobs.append(job)
                except Exception:
                    continue
            elif job["type"] == "one_time":
                # Only re-schedule if not yet past
                run_at = datetime.fromisoformat(job["run_at"])
                if run_at.tzinfo is None:
                    run_at = run_at.replace(tzinfo=timezone.utc)
                if run_at > now:
                    self.scheduler.add_job(
                        self._execute_action,
                        trigger=DateTrigger(run_date=run_at),
                        args=[job["target"], job["state"], job.get("reason", "")],
                        id=job["id"],
                    )
                    self.jobs.append(job)

    def _save_jobs(self):
        """Persist jobs to JSON file."""
        with open(JOBS_FILE, "w") as f:
            json.dump(self.jobs, f, indent=2)

    def add_one_time(self, target: str, state: str, run_at: datetime,
                     reason: str = "") -> dict:
        """Schedule a one-time action."""
        job_id = str(uuid.uuid4())[:8]

        self.scheduler.add_job(
            self._execute_action,
            trigger=DateTrigger(run_date=run_at),
            args=[target, state, reason],
            id=job_id,
        )

        job_info = {
            "id": job_id,
            "type": "one_time",
            "target": target,
            "state": state,
            "run_at": run_at.isoformat(),
            "reason": reason,
        }
        self.jobs.append(job_info)
        self._save_jobs()
        return job_info

    def add_recurring(self, target: str, state: str, hour: int, minute: int = 0,
                      days: str = "mon-sun", reason: str = "") -> dict:
        """Schedule a recurring action (cron-like)."""
        job_id = str(uuid.uuid4())[:8]

        day_map = {
            "mon-sun": "*", "weekday": "mon-fri",
            "weekend": "sat,sun",
        }
        day_of_week = day_map.get(days, days)

        self.scheduler.add_job(
            self._execute_action,
            trigger=CronTrigger(hour=hour, minute=minute, day_of_week=day_of_week),
            args=[target, state, reason],
            id=job_id,
        )

        job_info = {
            "id": job_id,
            "type": "recurring",
            "target": target,
            "state": state,
            "schedule": f"{hour:02d}:{minute:02d} ({days})",
            "reason": reason,
        }
        self.jobs.append(job_info)
        self._save_jobs()
        return job_info

    def add_delay(self, target: str, state: str, delay_minutes: int,
                  reason: str = "") -> dict:
        """Schedule action after N minutes from now."""
        run_at = datetime.now(timezone.utc) + timedelta(minutes=delay_minutes)
        return self.add_one_time(target, state, run_at, reason)

    def remove_job(self, job_id: str) -> bool:
        """Remove a scheduled job."""
        try:
            self.scheduler.remove_job(job_id)
        except Exception:
            pass
        before = len(self.jobs)
        self.jobs = [j for j in self.jobs if j["id"] != job_id]
        if len(self.jobs) < before:
            self._save_jobs()
            return True
        return False

    def get_all_jobs(self) -> list[dict]:
        """Get all scheduled jobs."""
        return self.jobs

    def _execute_action(self, target: str, state: str, reason: str):
        """Execute the scheduled smart home action."""
        self.controller.send_command(target, state, f"[Scheduled] {reason}")
        # Remove one-time jobs after execution
        self.jobs = [j for j in self.jobs if not (
            j["target"] == target and j["type"] == "one_time"
        )]
        self._save_jobs()
