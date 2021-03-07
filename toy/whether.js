const COORDS = "coords";
const API_KEY = "06ebe18239a62efb8b04104c062f0e5d";
const weather = document.querySelector(".js-weather");

function getWeather(latitude, longitude) {
  fetch(
    `https://api.openweathermap.org/data/2.5/weather?lat=${latitude}&lon=${longitude}&appid=${API_KEY}&units=metric`
  )
    .then(function (response) {
      return response.json();
    })
    .then(function (json) {
      const temperature = json.main.temp;
      const place = json.name;
      console.log(`${temperature} @ ${place}`);
      weather.innerText = `${temperature} @ ${place}`;
    });
}

function saveCoords(coordsObs) {
  localStorage.setItem(COORDS, JSON.stringify(coordsObs));
}

function handleGeoSuccess(position) {
  const latitude = position.coords.latitude;
  const longitude = position.coords.longitude;
  const coordsObs = {
    latitude,
    longitude,
  };
  saveCoords(coordsObs);
  getWeather(latitude, longitude);
}

function handleGeoError() {
  console.log("Cant access geo location");
}

function askForCoords() {
  navigator.geolocation.getCurrentPosition(handleGeoSuccess, handleGeoError);
  console.log("askForCoords is Done");
}

function loadCoords() {
  const loadedCoords = localStorage.getItem(COORDS);
  if (loadedCoords === null) {
    askForCoords();
  } else {
    a = JSON.parse(loadedCoords);
    console.log(a.latitude, a.longitude);
    lat = a.latitude;
    lon = a.longitude;
    getWeather(lat, lon);
  }
}

function init() {
  loadCoords();
}

init();
