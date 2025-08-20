import processing.sound.*;

 int NUM_TEXTURAS = 10;
 int NUM_FRAMES_ANIM = 10;
 int DURACION_ESPERA = 1000;
 int ZONA_CENTRAL_W = 200;
 int ZONA_CENTRAL_H = 150;
 int SEPARACION_BORDES = 80;
 int TIEMPO_LIMITE = 18000;

float grosorMin = 15, grosorMax = 60, grosorFijo = 50;
int texturaActual = 0;

PImage[] texturas = new PImage[NUM_TEXTURAS];
PImage[] animacionEncender = new PImage[NUM_FRAMES_ANIM];
PImage[] animacionEscalada = new PImage[NUM_FRAMES_ANIM]; 

PGraphics lienzo;
PGraphics lienzoCreciente;

PVector prevMouse;
float velocidad;
color colorActual;

SoundFile sonidoEncender, sonidoColor, sonidoGrosorUp, sonidoFondo;
SoundFile[] sonidosPinceles = new SoundFile[NUM_TEXTURAS];

boolean esperandoAnimacion = false;
boolean encendiendo = false;
boolean teleEncendida = false;
boolean teleApagada = true;
boolean manteniendoA = false;

int frameAnim = 0;
int delayAnim = 5, contadorDelay = 0;

long tiempoInicioEspera = 0;
long startDrawTime = 0;

color[] paleta = {
  #FF7C9D, #EC452E, #FE8F1F,
  #F8DD32, #4BA3FF, #FF9DFA, #5AC79E
};

float zonaRestringidaX, zonaRestringidaY, zonaRestringidaW, zonaRestringidaH;
float zonaInicialW = 1500;  // Tamaño de donde no se dibuja
float zonaInicialH = 1000;

float zonaDibujoX, zonaDibujoY, zonaDibujoW, zonaDibujoH;
float zonaDibujoInicialW = 1200;  
float zonaDibujoInicialH = 900;
float crecimientoVelocidad = 0; // Velocidad de crecimiento de la zona de dibujo
boolean dibujandoEnZonaCreciente = false;

void setup() {
  fullScreen();
  
  // Crear el buffer/lienzo donde se mantendrá el dibujo
  lienzo = createGraphics(width, height);
  lienzo.beginDraw();
  lienzo.background(0);
  lienzo.endDraw();
  
  // Crear el segundo lienzo para el área de dibujo creciente
  lienzoCreciente = createGraphics(width, height);
  lienzoCreciente.beginDraw();
  lienzoCreciente.clear(); // Transparente
  lienzoCreciente.endDraw();
  
  // Posicionar la zona restringida en el centro
  zonaRestringidaX = width/2 - zonaInicialW/2;
  zonaRestringidaY = height/2 - zonaInicialH/2;
  zonaRestringidaW = zonaInicialW;
  zonaRestringidaH = zonaInicialH;
  
  // Posicionar la zona de dibujo creciente en el centro
  zonaDibujoX = width/2 - zonaDibujoInicialW/2;
  zonaDibujoY = height/2 - zonaDibujoInicialH/2;
  zonaDibujoW = zonaDibujoInicialW;
  zonaDibujoH = zonaDibujoInicialH;
  
  reiniciarPrograma();
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
    // Actualizar el crecimiento de la zona de dibujo
    actualizarZonaDibujo();
    
    // Dibujar el fondo y la interfaz
    dibujarInterfaz();
    
    // Dibujar en el lienzo principal si el mouse NO está dentro de la zona restringida
    if (!mouseEnZonaRestringida()) {
      dibujarEnLienzoPrincipal();
    }
    
    // Dibujar en el lienzo creciente si el mouse está dentro de la zona de dibujo
    if (mouseEnZonaDibujo()) {
      dibujarEnLienzoCreciente();
    }
  } else {
    background(0);
  }
}

void keyPressed() {
  if (key == '2') cambiarColor();
  if (key == '?' || keyCode == 35) cambiarGrosor();
  if (key == 's' || key == 'S') cambiarTextura();
  if (key == 'a' || key == 'A') {
    manteniendoA = true;
    manejarEncendidoReinicio();
  }
  // Reinicio completo con la tecla R
  if (key == 'r' || key == 'R') {
    reiniciarPrograma();
  }
}

void keyReleased() {
  if (key == 'a' || key == 'A') {
    manteniendoA = false;
    
    // Si estamos en modo loop (frames 6-8) y soltamos A, continuar la animación normal
    if (encendiendo && frameAnim >= 6 && frameAnim <= 8) {
      frameAnim = 9; // Saltar al último frame para completar la animación
      contadorDelay = 0;
    }
  }
}

// .......................................................

void cargarTexturas() {
  for (int i = 0; i < NUM_TEXTURAS; i++) {
    texturas[i] = loadImage("Recurso_" + (322 + i) + ".png");
    if (texturas[i] == null) {
      println("Error cargando textura: Recurso_" + (322 + i) + ".png");
    }
  }
}

void cargarAnimacion() {
  for (int i = 0; i < NUM_FRAMES_ANIM; i++) {
    animacionEncender[i] = loadImage("tele" + i + ".png");
    if (animacionEncender[i] != null) {
      animacionEscalada[i] = createImage(width, height, RGB);
      animacionEncender[i].resize(width, height);
      animacionEscalada[i] = animacionEncender[i].get();
    } else {
      println("Error cargando frame de animación: tele" + i + ".png");
    }
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
    println("Error cargando sonido: " + path);
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
  if (manteniendoA && frameAnim >= 6 && frameAnim <= 8) {
    if (++contadorDelay >= delayAnim) {
      if (frameAnim == 6) frameAnim = 7;
      else if (frameAnim == 7) frameAnim = 8;
      else if (frameAnim == 8) frameAnim = 6;
      contadorDelay = 0;
    }
  } else if (frameAnim < NUM_FRAMES_ANIM - 1) {
    if (++contadorDelay >= delayAnim) {
      frameAnim++;
      contadorDelay = 0;
    }
  } else if (frameAnim == NUM_FRAMES_ANIM - 1) {
    encendiendo = false;
    teleEncendida = true;
    background(0);
    prevMouse = new PVector(mouseX, mouseY);
    startDrawTime = millis();
    
    return;
  }
  
  background(0);
  if (animacionEscalada[frameAnim] != null) {
    image(animacionEscalada[frameAnim], 0, 0);
  } else if (animacionEncender[frameAnim] != null) {
    image(animacionEncender[frameAnim], 0, 0, width, height);
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
  if (teleEncendida) {
    reiniciarPrograma();
    if (sonidoEncender != null) sonidoEncender.play();
  } else if (!encendiendo && !teleEncendida) {
    encendiendo = true;
    frameAnim = 0;
    contadorDelay = 0;
    if (sonidoEncender != null) sonidoEncender.play();
    teleApagada = false;
    background(0);
  }
}

void reproducirSonidoBrocha() {
  if (!teleEncendida || sonidosPinceles == null) return;
  for (SoundFile s : sonidosPinceles) if (s != null) s.stop();
  if (sonidosPinceles[texturaActual] != null) sonidosPinceles[texturaActual].play();
}

void reiniciarPrograma() {
  background(0);
  noStroke();
  noCursor();
  
  lienzo.beginDraw();
  lienzo.background(0);
  lienzo.endDraw();
  
  lienzoCreciente.beginDraw();
  lienzoCreciente.clear();
  lienzoCreciente.endDraw();
  
  esperandoAnimacion = true;
  encendiendo = false;
  teleEncendida = false;
  teleApagada = true;
  manteniendoA = false;
  
  frameAnim = 0;
  contadorDelay = 0;
  
  prevMouse = new PVector(mouseX, mouseY);
  
  texturaActual = 0;
  colorActual = paleta[0];
  grosorFijo = 50;
  
  zonaRestringidaX = width/2 - zonaInicialW/2;
  zonaRestringidaY = height/2 - zonaInicialH/2;
  zonaRestringidaW = zonaInicialW;
  zonaRestringidaH = zonaInicialH;
  
  zonaDibujoX = width/2 - zonaDibujoInicialW/2;
  zonaDibujoY = height/2 - zonaDibujoInicialH/2;
  zonaDibujoW = zonaDibujoInicialW;
  zonaDibujoH = zonaDibujoInicialH;
  dibujandoEnZonaCreciente = false;
  
  tiempoInicioEspera = millis();
  startDrawTime = 0;
  
  if (sonidoEncender != null) sonidoEncender.stop();
  if (sonidoColor != null) sonidoColor.stop();
  if (sonidoGrosorUp != null) sonidoGrosorUp.stop();
  for (SoundFile s : sonidosPinceles) if (s != null && s.isPlaying()) s.stop();
  if (sonidoFondo != null && sonidoFondo.isPlaying()) sonidoFondo.stop();
}

void reiniciarTodo() {
  reiniciarPrograma();
}

// .......................................................

void actualizarZonaDibujo() {
  if (zonaDibujoW < width * 0.8) {
    zonaDibujoW += crecimientoVelocidad;
    zonaDibujoH += crecimientoVelocidad;
    zonaDibujoX = width/2 - zonaDibujoW/2;
    zonaDibujoY = height/2 - zonaDibujoH/2;
  }
}

void dibujarInterfaz() {
  background(0);
  image(lienzo, 0, 0);
  image(lienzoCreciente, 0, 0);
  
  // Dibujar la zona restringida (donde NO se puede dibujar)
  fill(0);
  stroke(150);
  rect(zonaRestringidaX, zonaRestringidaY, zonaRestringidaW, zonaRestringidaH);
  
  // Dibujar la zona de dibujo creciente
  fill(255, 20);
  stroke(0, 255, 0);
  rect(zonaDibujoX, zonaDibujoY, zonaDibujoW, zonaDibujoH);
  
  // Indicador visual para zona restringida
  if (mouseEnZonaRestringida()) {
    fill(255, 0, 0, 50);
    noStroke();
    ellipse(mouseX, mouseY, 20, 20);
  }
  
  // Indicador visual para zona de dibujo
  if (mouseEnZonaDibujo()) {
    fill(0, 255, 0, 50);
    noStroke();
    ellipse(mouseX, mouseY, 20, 20);
  }
  
  noStroke();
}

boolean mouseEnZonaRestringida() {
  return mouseX >= zonaRestringidaX && mouseX <= zonaRestringidaX + zonaRestringidaW &&
         mouseY >= zonaRestringidaY && mouseY <= zonaRestringidaY + zonaRestringidaH;
}

boolean mouseEnZonaDibujo() {
  return mouseX >= zonaDibujoX && mouseX <= zonaDibujoX + zonaDibujoW &&
         mouseY >= zonaDibujoY && mouseY <= zonaDibujoY + zonaDibujoH;
}

void dibujarEnLienzoPrincipal() {
  PVector actual = new PVector(mouseX, mouseY);
  velocidad = PVector.dist(actual, prevMouse);
  int pasos = constrain(int(velocidad / 2), 1, 10);
  float alpha = constrain(map(velocidad, 0, 50, 255, 50), 50, 255);

  lienzo.beginDraw();
  lienzo.tint(colorActual, alpha);
  lienzo.imageMode(CENTER);
  
  for (int i = 0; i <= pasos; i++) {
    float t = map(i, 0, pasos, 0, 1);
    float x = lerp(prevMouse.x, actual.x, t);
    float y = lerp(prevMouse.y, actual.y, t);
    lienzo.image(texturas[texturaActual], x, y, grosorFijo, grosorFijo);
  }
  
  lienzo.endDraw();
  prevMouse.set(actual);
}

void dibujarEnLienzoCreciente() {
  PVector actual = new PVector(mouseX, mouseY);
  velocidad = PVector.dist(actual, prevMouse);
  int pasos = constrain(int(velocidad / 2), 1, 10);
  float alpha = constrain(map(velocidad, 0, 50, 255, 50), 50, 255);

  lienzoCreciente.beginDraw();
  lienzoCreciente.tint(colorActual, alpha);
  lienzoCreciente.imageMode(CENTER);
  
  for (int i = 0; i <= pasos; i++) {
    float t = map(i, 0, pasos, 0, 1);
    float x = lerp(prevMouse.x, actual.x, t);
    float y = lerp(prevMouse.y, actual.y, t);
    lienzoCreciente.image(texturas[texturaActual], x, y, grosorFijo, grosorFijo);
  }
  
  lienzoCreciente.endDraw();
  prevMouse.set(actual);
  
  dibujandoEnZonaCreciente = true;
}
