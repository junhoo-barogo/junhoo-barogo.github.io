const COORDS = "coords";

function handleGeoSuccess(position) {
  console.log(position);
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
