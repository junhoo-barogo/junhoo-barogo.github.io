const COORDS = "coords";

function saveCoords(coordsObs) {
  localStorage.setItem(COORDS, JSON.stringify(coordsObs));
}

function handleGeoSuccess(position) {
  const latitude = position.coords.latitude;
  const longtitude = position.coords.longtitude;
  const coordsObs = {
    latitude,
    longtitude,
  };
  saveCoords(coordsObs);
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
    //get Whether
  }
}

function init() {
  loadCoords();
}

init();
