const clockContatainer = document.querySelector(".js-clock");
const clockTitle = clockContatainer.querySelector("h1");

function getTime() {
  const date = new Date();
  const minutes = date.getMinutes();
  const hours = date.getHours();
  clockTitle.innerText = `${hours}:${minutes}`;
}

function init() {
  getTime();
}

init();
