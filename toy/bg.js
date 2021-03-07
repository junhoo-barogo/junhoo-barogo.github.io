const body = document.querySelector("body");
const IMG_NUMBER = 3;

function paintImage(imgNumber) {
  const image = new Image();
  image.src = `images/${imgNumber}.jpg`;
  image.classList.add("bgImage");
  body.prepend(image);
}

function init() {
  const number = Math.ceil(Math.random() * IMG_NUMBER);
  paintImage(number);
}

init();
