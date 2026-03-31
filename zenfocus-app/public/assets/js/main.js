(function () {
  const home = document.querySelector('.home-layout');
  const timerValue = document.getElementById('timer-value');
  const startBtn = document.getElementById('start-btn');
  const pauseBtn = document.getElementById('pause-btn');
  const resetBtn = document.getElementById('reset-btn');
  const modeTabs = document.querySelectorAll('.tab-btn[data-mode]');
  const finishAt = document.getElementById('finish-at');
  const remainingHours = document.getElementById('remaining-hours');

  let timerRef = null;

  if (home && timerValue && startBtn && pauseBtn && resetBtn && modeTabs.length > 0) {
    const durations = {
      pomodoro: Math.max(1, Number(home.dataset.pomodoroMinutes || 40)),
      short_break: Math.max(1, Number(home.dataset.shortBreakMinutes || 5)),
      long_break: Math.max(1, Number(home.dataset.longBreakMinutes || 15)),
    };

    let mode = home.dataset.initialMode || 'pomodoro';
    let remaining = durations[mode] * 60;

    function formatClock(totalSeconds) {
      const safe = Math.max(0, totalSeconds);
      const mm = Math.floor(safe / 60).toString().padStart(2, '0');
      const ss = (safe % 60).toString().padStart(2, '0');
      return `${mm}:${ss}`;
    }

    function refreshMeta() {
      if (!finishAt || !remainingHours) return;

      const finish = new Date(Date.now() + remaining * 1000);
      const hh = finish.getHours().toString().padStart(2, '0');
      const mm = finish.getMinutes().toString().padStart(2, '0');
      finishAt.textContent = `${hh}:${mm}`;
      remainingHours.textContent = `${(remaining / 3600).toFixed(1)}h`;
    }

    function render() {
      timerValue.textContent = formatClock(remaining);
      modeTabs.forEach((tab) => {
        tab.classList.toggle('is-active', tab.dataset.mode === mode);
      });
      refreshMeta();
    }

    function stopTimer() {
      if (timerRef !== null) {
        window.clearInterval(timerRef);
        timerRef = null;
      }
    }

    function resetCurrentMode() {
      stopTimer();
      remaining = durations[mode] * 60;
      render();
    }

    startBtn.addEventListener('click', function () {
      if (timerRef !== null) return;

      timerRef = window.setInterval(function () {
        remaining -= 1;
        if (remaining <= 0) {
          remaining = 0;
          stopTimer();
        }
        render();
      }, 1000);
    });

    pauseBtn.addEventListener('click', stopTimer);
    resetBtn.addEventListener('click', resetCurrentMode);

    modeTabs.forEach((tab) => {
      tab.addEventListener('click', function () {
        mode = tab.dataset.mode;
        resetCurrentMode();
      });
    });

    render();
  }

  const deleteForms = document.querySelectorAll('form[data-delete-form="true"]');
  if (deleteForms.length === 0) return;

  deleteForms.forEach((form) => {
    form.addEventListener('submit', function (event) {
      const ok = window.confirm('Delete this task? This action cannot be undone.');
      if (!ok) {
        event.preventDefault();
      }
    });
  });
})();
