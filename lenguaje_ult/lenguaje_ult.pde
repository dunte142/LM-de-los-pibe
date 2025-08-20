import processing.sound.*; //<>//

final int NUM_TEXTURAS = 10;
final int NUM_FRAMES_ANIM = 10;
final int DURACION_ESPERA = 1000;
final int ZONA_CENTRAL_W = 200;
final int ZONA_CENTRAL_H = 150;
final int SEPARACION_BORDES = 80;
final int TIEMPO_LIMITE = 18000;

float grosorMin = 15, grosorMax = 60, grosorFijo = 50;
int texturaActual = 0;

PImage[] texturas = new PImage[NUM_TEXTURAS];
PImage[] animacionEncender = new PImage[NUM_FRAMES_ANIM];

PVector prevMouse;
float velocidad;
color colorActual;

SoundFile sonidoEncender, sonidoColor, sonidoGrosorUp, sonidoFondo;
SoundFile[] sonidosPinceles = new SoundFile[NUM_TEXTURAS];

boolean esperandoAnimacion = false;
boolean encendiendo = false;
boolean teleEncendida = false;
boolean teleApagada = true;

int frameAnim = 0;
int delayAnim = 5, contadorDelay = 0;

long tiempoInicioEspera = 0;
long startDrawTime = 0;

color[] paleta = {
  #FF7C9D, #EC452E, #FE8F1F,
  #F8DD32, #4BA3FF, #FF9DFA, #5AC79E
};

void setup() {
  fullScreen();
  background(0);
  noStroke();
  noCursor();
  prevMouse = new PVector(mouseX, mouseY);
  colorActual = paleta[0];

  cargarTexturas();
  cargarAnimacion();
  cargarSonidos();
}

void draw() {
  if (esperandoAnimacion) {
    manejarEsperaAnimacion();
  } else if (encendiendo) {
    mostrarAnimacionEncender();
  } else if (teleEncendida) {
    dibujar();
  } else {
    background(0);
  }
}

void keyPressed() {
  if (key == '2') cambiarColor();
  if (key == '?' || keyCode == 35) cambiarGrosor();
  if (key == 's' || key == 'S') cambiarTextura();
  if (key == 'a' || key == 'A') manejarEncendidoReinicio();
}

// .......................................................

void cargarTexturas() {
  for (int i = 0; i < NUM_TEXTURAS; i++) {
    texturas[i] = loadImage("Recurso_" + (322 + i) + ".png");
  }
}

void cargarAnimacion() {
  for (int i = 0; i < NUM_FRAMES_ANIM; i++) {
    animacionEncender[i] = loadImage("tele" + i + ".png");
  }
}

void cargarSonidos() {
  sonidoEncender = cargarSonido("sonidos/encender.mp3");
  sonidoColor = cargarSonido("sonidos/color.mp3");
  sonidoGrosorUp = cargarSonido("sonidos/grosorUp.mp3");
  sonidoFondo = new SoundFile(this, "estatica.mp3");

  for (int i = 0; i < NUM_TEXTURAS; i++) {
    sonidosPinceles[i] = cargarSonido("sonidos/pincel" + i + ".mp3");
  }
}

SoundFile cargarSonido(String path) {
  try {
    SoundFile s = new SoundFile(this, path);
    return s.duration() > 0 ? s : null;
  } catch (Exception e) {
    return null;
  }
}

// .......................................................

void manejarEsperaAnimacion() {
  background(0);
  if (millis() - tiempoInicioEspera > DURACION_ESPERA) {
    esperandoAnimacion = false;
    encendiendo = true;
    frameAnim = contadorDelay = 0;
    if (sonidoEncender != null) sonidoEncender.play();
  }
}

void mostrarAnimacionEncender() {
  background(0);
  if (frameAnim < NUM_FRAMES_ANIM) {
    int zonaX = (width - ZONA_CENTRAL_W) / 2;
    int zonaY = (height - ZONA_CENTRAL_H) / 2;
    image(animacionEncender[frameAnim], zonaX, zonaY, ZONA_CENTRAL_W, ZONA_CENTRAL_H);
    if (++contadorDelay >= delayAnim) {
      frameAnim++;
      contadorDelay = 0;
    }
  } else {
    encendiendo = false;
    teleEncendida = true;
    background(0);
    prevMouse.set(mouseX, mouseY);
    startDrawTime = millis();
  }
}

// .......................................................

void cambiarColor() {
  int index = (getColorIndex(colorActual) + 1) % paleta.length;
  colorActual = paleta[index];
  if (sonidoColor != null) {
    sonidoColor.stop();
    sonidoColor.play();
  }
}

int getColorIndex(color c) {
  for (int i = 0; i < paleta.length; i++) {
    if (paleta[i] == c) return i;
  }
  return 0;
}

void cambiarGrosor() {
  grosorFijo += 1;
  if (grosorFijo > grosorMax) grosorFijo = grosorMin;
  if (sonidoGrosorUp != null) sonidoGrosorUp.play();
}

void cambiarTextura() {
  texturaActual = (texturaActual + 1) % NUM_TEXTURAS;
  reproducirSonidoBrocha();
}

void manejarEncendidoReinicio() {
  if (!encendiendo && !teleEncendida) {
    encendiendo = true;
frameAnim = 0;
contadorDelay = 0;
if (sonidoEncender != null) sonidoEncender.play();

    teleApagada = false;
    background(0);
  } else if (teleEncendida) {
    reiniciarTodo();
    if (sonidoEncender != null) sonidoEncender.play();
  }
}

void reproducirSonidoBrocha() {
  if (!teleEncendida || sonidosPinceles == null) return;
  for (SoundFile s : sonidosPinceles) if (s != null) s.stop();
  if (sonidosPinceles[texturaActual] != null) sonidosPinceles[texturaActual].play();
}

void reiniciarTodo() {
  encendiendo = teleEncendida = false;
  teleApagada = true;
  frameAnim = 0;
  background(0);
  prevMouse.set(mouseX, mouseY);
  texturaActual = 0;
  colorActual = color(255);
  grosorFijo = 25;

  if (sonidoEncender != null) sonidoEncender.stop();
  if (sonidoColor != null) sonidoColor.stop();
  if (sonidoGrosorUp != null) sonidoGrosorUp.stop();
  for (SoundFile s : sonidosPinceles) if (s != null && s.isPlaying()) s.stop();
  if (sonidoFondo != null && sonidoFondo.isPlaying()) sonidoFondo.stop();
}

// .......................................................

void dibujar() {
  int centroX = width / 2, centroY = height / 2;
  int zonaX1 = centroX - ZONA_CENTRAL_W / 2;
  int zonaX2 = centroX + ZONA_CENTRAL_W / 2;
  int zonaY1 = centroY - ZONA_CENTRAL_H / 2;
  int zonaY2 = centroY + ZONA_CENTRAL_H / 2;

  boolean dibujarLibre = (millis() - startDrawTime > TIEMPO_LIMITE);
  boolean permitido = esPermitidoDibujar(dibujarLibre, zonaX1, zonaX2, zonaY1, zonaY2);

  color c = permitido ? colorActual : color(0);
  PVector actual = new PVector(mouseX, mouseY);
  velocidad = PVector.dist(actual, prevMouse);
  int pasos = constrain(int(velocidad / 2), 1, 10);
  float alpha = constrain(map(velocidad, 0, 50, 255, 50), 50, 255);

  for (int i = 0; i <= pasos; i++) {
    float t = map(i, 0, pasos, 0, 1);
    float x = lerp(prevMouse.x, actual.x, t);
    float y = lerp(prevMouse.y, actual.y, t);
    tint(c, alpha);
    imageMode(CENTER);
    image(texturas[texturaActual], x, y, grosorFijo, grosorFijo);
  }

  prevMouse.set(actual);
  mostrarGuias(zonaX1, zonaX2, zonaY1, zonaY2);
}

boolean esPermitidoDibujar(boolean libre, int x1, int x2, int y1, int y2) {
  if (!libre) {
    return mouseX > x1 && mouseX < x2 && mouseY > y1 && mouseY < y2;
  }
  boolean dentroCentral = mouseX > x1 && mouseX < x2 && mouseY > y1 && mouseY < y2;
  boolean lateralIzq = mouseX < x1 - SEPARACION_BORDES;
  boolean lateralDer = mouseX > x2 + SEPARACION_BORDES;
  boolean superior = mouseY < y1 - SEPARACION_BORDES;
  boolean fueraInferior = mouseY > y2 + SEPARACION_BORDES;
  return (dentroCentral || lateralIzq || lateralDer || superior) && !fueraInferior;
}

void mostrarGuias(int x1, int x2, int y1, int y2) {
  noFill();
  stroke(0, 0, 0, 0);
  strokeWeight(2);
  rectMode(CENTER);
  rect(width / 2, height / 2, ZONA_CENTRAL_W, ZONA_CENTRAL_H);

  rectMode(CORNER);
  rect(0, 0, x1 - SEPARACION_BORDES, height);
  rect(x2 + SEPARACION_BORDES, 0, width - x2 - SEPARACION_BORDES, height);
  rect(0, 0, width, y1 - SEPARACION_BORDES);
  rect(0, y2 + SEPARACION_BORDES, width, height - y2 - SEPARACION_BORDES);
}
