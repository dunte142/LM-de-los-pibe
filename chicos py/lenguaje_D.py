import pygame
import sys
import os
import math
import random


# Config

NOMBRE = "lenguaje_D"
NUM_TEXTURAS = 10         # texturas 
NUM_FRAMES_ANIM = 10      # animación
DURACION_ESPERA = 1000    # espera antes de animación
ZONA_CENTRAL_W = 600      # ancho zona central 
ZONA_CENTRAL_H = 450      # alto zona central 
CUADRADO_INICIAL = 100    # tamaño inicial del cuadrado dibujable
TIEMPO_EXPANSION = 18000  # tiempo para expansión completa (18s)
TIEMPO_CRECIMIENTO = 3000 # tiempo entre cada crecimiento (3s)

COLORES = [
    (255, 124, 157), (236, 69, 46), (254, 143, 31),
    (248, 221, 50), (75, 163, 255), (255, 157, 250), (90, 199, 158)
]


# Clase Madre

class LenguajeD:
    def __init__(self, screen):
        self.screen = screen
        self.width, self.height = screen.get_size()

        # ---- Recursos ----
        self.texturas = [self.cargar_textura(f"Recurso_{i}.png") 
                         for i in range(NUM_TEXTURAS)]
        self.animacion = [self.cargar_imagen(f"tele{i}.png") 
                          for i in range(NUM_FRAMES_ANIM)]

        self.sonidos = {
            "encender": self.cargar_sonido("sonidos/encender.mp3"),
            "color": self.cargar_sonido("sonidos/color.mp3"),
            "grosorUp": self.cargar_sonido("sonidos/grosorUp.mp3"),
            "fondo": self.cargar_sonido("estatica.mp3"),
            "expansion": self.cargar_sonido("sonidos/expansion.mp3"),
        }
        
        # S de pinceles
        self.sonidos_pinceles = [self.cargar_sonido(f"sonidos/pincel{i}.mp3") 
                                for i in range(NUM_TEXTURAS)]
        
        #sonido continuo
        self.sonido_actual = None
        self.ultimo_sonido_tiempo = 0
        self.sonido_intervalo = 100 

        # ---- Estados ----
        self.estado = "apagado"  # apagado / animando / prendido / apagando
        self.frame_anim = 0
        self.last_anim_time = 0
        self.tecla_a_presionada = False
        self.ultimo_crecimiento = 0
        self.primera_vez_a = True  # Para saber si es la primera vez que se presiona A
        self.apagando = False  # Para controlar la animación de apagado

        # ---- Dibujo ----
        self.textura_actual = 0
        self.color_actual = COLORES[0]
        self.grosor_min = 15
        self.grosor_max = 60
        self.grosor_fijo = 25
        self.prev_pos = None
        self.velocidad = 0
        
        # Lienzo para mantener el dibujo
        self.lienzo = pygame.Surface((self.width, self.height), pygame.SRCALPHA)
        self.lienzo.fill((0, 0, 0, 0))  # Lienzo transparente

        # ---- Zonas ----
        self.centro_x = self.width // 2
        self.centro_y = self.height // 2
        
        # Rectángulo central grande (no dib)
        self.zona_prohibida = pygame.Rect(
            self.centro_x - ZONA_CENTRAL_W // 2,
            self.centro_y - ZONA_CENTRAL_H // 2,
            ZONA_CENTRAL_W,
            ZONA_CENTRAL_H
        )
        
        # Cuadrado central pequeño (dib)
        self.tamano_cuadrado = CUADRADO_INICIAL
        self.zona_permitida = pygame.Rect(
            self.centro_x - self.tamano_cuadrado // 2,
            self.centro_y - self.tamano_cuadrado // 2,
            self.tamano_cuadrado,
            self.tamano_cuadrado
        )
        
        # Etapas de crecimientp
        self.etapa_expansion = 0
        self.max_etapas = int(TIEMPO_EXPANSION / TIEMPO_CRECIMIENTO)

    def cargar_imagen(self, path):
        if os.path.exists(path):
            return pygame.image.load(path).convert_alpha()
        
        print(f"Advertencia: No se encontró {path}, usando imagen de prueba") # X las dudas
        surf = pygame.Surface((50, 50), pygame.SRCALPHA)
        color = (random.randint(100, 255), random.randint(100, 255), random.randint(100, 255), 200)
        pygame.draw.circle(surf, color, (25, 25), 20)
        for i in range(10):
            x, y = random.randint(5, 45), random.randint(5, 45)
            pygame.draw.circle(surf, (255, 255, 255, 100), (x, y), random.randint(1, 3))
        return surf
        
    def cargar_textura(self, path):
        
        posibles_rutas = [ # X si no las encuentra
            path,
            f"texturas/{path}",
            f"recursos/{path}",
            f"assets/{path}",
            f"Recurso_{random.randint(0, NUM_TEXTURAS-1)}.png"
        ]
        
        for ruta in posibles_rutas:
            if os.path.exists(ruta):
                img = pygame.image.load(ruta).convert_alpha()
                print(f"Cargada textura: {ruta}")
                return img
        
       
        print(f"Advertencia: No se encontró {path}, creando textura procedural") # X las dudas
        size = 64
        surf = pygame.Surface((size, size), pygame.SRCALPHA)
        
       
        for i in range(100):
            x, y = random.randint(0, size-1), random.randint(0, size-1)
            radius = random.randint(2, 8)
            alpha = random.randint(50, 200)
            color = (random.randint(200, 255), random.randint(200, 255), random.randint(200, 255), alpha)
            pygame.draw.circle(surf, color, (x, y), radius)
            
        return surf

    def cargar_sonido(self, path):
        if os.path.exists(path):
            return pygame.mixer.Sound(path)
        
        
        posibles_rutas = [ # X las dudas
            path,
            f"sonidos/{path}",
            f"sounds/{path}",
            f"audio/{path}",
        ]
        
        for ruta in posibles_rutas:
            if os.path.exists(ruta):
                return pygame.mixer.Sound(ruta)
        
        print(f"Advertencia: No se encontró el sonido {path}")
        return None

    # ---- ESTADOS ----
    def apagar(self):
        self.estado = "apagado"
        self.frame_anim = 0
        self.prev_pos = None
        # Reinicia el lienzo
        self.lienzo.fill((0, 0, 0, 0))
        # Reiniciar cuadrado no dib
        self.tamano_cuadrado = CUADRADO_INICIAL
        self.etapa_expansion = 0
        self.actualizar_zona_permitida()
        
        # Detener todos los sonidos
        pygame.mixer.stop()
        self.sonido_actual = None
        self.tecla_a_presionada = False
        self.primera_vez_a = True  # Resetear para la próxima vez
        self.apagando = False  # Resetear estado de apagado

    def iniciar_animacion(self):
        self.estado = "animando"
        self.frame_anim = 0
        self.last_anim_time = pygame.time.get_ticks()
        
        # Reproducir sonido de estática en loop
        if self.sonidos["fondo"]:
            self.sonidos["fondo"].play(-1)  # -1 para loop infinito

    def iniciar_apagado(self):
        self.estado = "apagando"
        self.frame_anim = 4  # Empezar desde el frame 4
        self.last_anim_time = pygame.time.get_ticks()
        
        # Reproducir sonido de encendido (pero para apagado)
        if self.sonidos["encender"]:
            self.sonidos["encender"].play()

    def detener_animacion(self):
        if self.estado == "animando":
            self.estado = "prendido"
            self.prev_pos = pygame.math.Vector2(pygame.mouse.get_pos())
            self.start_draw_time = pygame.time.get_ticks()
            self.ultimo_crecimiento = pygame.time.get_ticks()
            
            # Detener sonido de estática
            if self.sonidos["fondo"] and self.sonidos["fondo"].get_num_channels() > 0:
                self.sonidos["fondo"].stop()

    def actualizar_animacion(self):
        now = pygame.time.get_ticks()
        if now - self.last_anim_time > 100:  # 10 fps
            if self.estado == "animando":
                if self.primera_vez_a:
                    # Primera vez: animación completa (frames 0-9)
                    self.frame_anim += 1
                    if self.frame_anim >= NUM_FRAMES_ANIM:
                        # Cuando termina la primera animación, ya no es la primera vez
                        self.primera_vez_a = False
                        self.frame_anim = 5  # Empezar desde el frame 5 para el loop
                else:
                    # Después de la primera vez: loop con frames 5-6-7-8
                    self.frame_anim = 5 + ((self.frame_anim - 5 + 1) % 4)  # Loop entre frames 5-8
            
            elif self.estado == "apagando":
                # Animación de apagado: frames 4-3-2-1
                self.frame_anim -= 1
                if self.frame_anim < 1:  # Cuando llega al frame 1, termina
                    self.apagar()  # Reiniciar todo
            
            self.last_anim_time = now

    def dibujar_animacion(self):
        # Dibujar la animación centrada
        img = self.animacion[self.frame_anim]
        img_rect = img.get_rect(center=(self.centro_x, self.centro_y))
        self.screen.blit(img, img_rect)

    def actualizar_expansion(self):
        now = pygame.time.get_ticks()
        
        
        if now - self.ultimo_crecimiento > TIEMPO_CRECIMIENTO and self.etapa_expansion < self.max_etapas:
            self.etapa_expansion += 1
            
            
            progreso = self.etapa_expansion / self.max_etapas
            nuevo_tamano = CUADRADO_INICIAL + (ZONA_CENTRAL_W - CUADRADO_INICIAL) * progreso
            
            self.tamano_cuadrado = nuevo_tamano
            self.actualizar_zona_permitida()
            
            self.ultimo_crecimiento = now
            

    def actualizar_zona_permitida(self):
        self.zona_permitida = pygame.Rect(
            self.centro_x - self.tamano_cuadrado // 2,
            self.centro_y - self.tamano_cuadrado // 2,
            self.tamano_cuadrado,
            self.tamano_cuadrado
        )

    def dibujar_prendido(self):
        
        self.actualizar_expansion()
        
       
        self.screen.blit(self.lienzo, (0, 0))
        
        
        self.procesar_dibujo()

    def procesar_dibujo(self):
        mouse_pos = pygame.math.Vector2(pygame.mouse.get_pos())
        
        # Dibuja al pasar el mouse
        permitido = self.es_permitido_dibujar(mouse_pos)
        
        # Calcular velocidad para el efecto de trazo
        if self.prev_pos:
            self.velocidad = mouse_pos.distance_to(self.prev_pos)
        
        # Dibujar trazo continuo
        if self.prev_pos and permitido and self.velocidad > 0.5:
            self.dibujar_trazo(self.prev_pos, mouse_pos, self.color_actual)
            
            # Controlar sonido continuo
            self.controlar_sonido_continuo()
        
        self.prev_pos = mouse_pos
        
        
        #DIBUJAR SOLO SI SE APRETA EL CLIC
        
        
        
          #  def procesar_dibujo(self):
        # mouse_pos = pygame.math.Vector2(pygame.mouse.get_pos())
        #mouse_pressed = pygame.mouse.get_pressed()[0]  
        
        #if mouse_pressed:
            # Calcular si está permitido dibujar aquí
        #    permitido = self.es_permitido_dibujar(mouse_pos)
            
            # Color (si estás en la zona no dib se pinta de negro simulando que no se dibuja nada)
        #    color = self.color_actual if permitido else (0, 0, 0)
            
            # Calcular velocidad para desgastar el trazo
        #     if self.prev_pos:
        #        self.velocidad = mouse_pos.distance_to(self.prev_pos)
            
            # Dibujar trazo
        #   if self.prev_pos and permitido:
        #        self.dibujar_trazo(self.prev_pos, mouse_pos, color)
                
                # Controlar sonido continuo
        #       self.controlar_sonido_continuo()
            
        #    self.prev_pos = mouse_pos
        # else:
        #    self.prev_pos = None
            # Detener sonido cuando no se dibuja
        #    if self.sonido_actual and self.sonido_actual.get_num_channels() > 0:
        #        self.sonido_actual.stop()
        #   self.sonido_actual = None
        
        
        
        
        #--------------------------------------------------------------------------------------------------------------------------------
        
        
        
        
        

    def controlar_sonido_continuo(self):
        now = pygame.time.get_ticks()
        
        
        if now - self.ultimo_sonido_tiempo > self.sonido_intervalo and self.velocidad > 1:
            
            if (self.sonido_actual and 
                self.sonidos_pinceles[self.textura_actual] != self.sonido_actual and
                self.sonido_actual.get_num_channels() > 0):
                self.sonido_actual.stop()
            
            
            if (self.sonidos_pinceles[self.textura_actual] and 
                self.sonidos_pinceles[self.textura_actual].get_length() > 0):
                self.sonido_actual = self.sonidos_pinceles[self.textura_actual]
                if self.sonido_actual.get_num_channels() == 0:  
                    self.sonido_actual.play()
            
            self.ultimo_sonido_tiempo = now

    def dibujar_trazo(self, inicio, fin, color):
       
        pasos = max(1, min(10, int(self.velocidad / 2)))
        
        # Calcular alpha basado en la velocidad
        alpha = max(50, min(255, 255 - (self.velocidad * 4)))
        
        # Crear textura con el color and alpha apropiados
        textura = self.texturas[self.textura_actual]
        textura = pygame.transform.scale(textura, (self.grosor_fijo, self.grosor_fijo))
        tex = textura.copy()
        tex.fill(color + (alpha,), special_flags=pygame.BLEND_RGBA_MULT)
        
        # Dibujar 
        for i in range(pasos + 1):
            t = i / pasos
            x = pygame.math.lerp(inicio.x, fin.x, t)
            y = pygame.math.lerp(inicio.y, fin.y, t)
            
            
            tex_rect = tex.get_rect(center=(x, y))
            self.lienzo.blit(tex, tex_rect)
            
            
            self.screen.blit(tex, tex_rect)

    def es_permitido_dibujar(self, pos):
        x, y = pos.x, pos.y
        
        # NO se puede dibujar en el rectángulo grande 
        if self.zona_prohibida.collidepoint(x, y):
            # Se puede dibujar en el centro chiquito
            return self.zona_permitida.collidepoint(x, y)
        
        
        return True

    # ---- Controles ----
    def cambiar_color(self):
        idx = (COLORES.index(self.color_actual) + 1) % len(COLORES)
        self.color_actual = COLORES[idx]
        if self.sonidos["color"]: 
            self.sonidos["color"].stop()
            self.sonidos["color"].play()

    def cambiar_grosor(self):
        self.grosor_fijo += 5
        if self.grosor_fijo > self.grosor_max: 
            self.grosor_fijo = self.grosor_min
        if self.sonidos["grosorUp"]: 
            self.sonidos["grosorUp"].play()

    def cambiar_textura(self):
        self.textura_actual = (self.textura_actual + 1) % NUM_TEXTURAS
        
        if self.sonido_actual and self.sonido_actual.get_num_channels() > 0:
            self.sonido_actual.stop()
        self.sonido_actual = None
        
        if (self.sonidos_pinceles[self.textura_actual] and 
            self.sonidos_pinceles[self.textura_actual].get_length() > 0):
            self.sonidos_pinceles[self.textura_actual].play()

    # ---- Loop ----
    def update(self):
        if self.estado == "apagado":
            self.screen.fill((0, 0, 0))
        elif self.estado == "animando" or self.estado == "apagando":
            self.screen.fill((0, 0, 0))
            self.actualizar_animacion()
            self.dibujar_animacion()
        elif self.estado == "prendido":
            self.screen.fill((0, 0, 0))
            self.dibujar_prendido()


def main():
    pygame.init()
    pygame.mixer.init()
    screen = pygame.display.set_mode((0, 0), pygame.FULLSCREEN)
    pygame.display.set_caption(NOMBRE)
    clock = pygame.time.Clock()

    juego = LenguajeD(screen)


     # A para Prender y Apagar
     # Si mantengo A me quedo en la estatica
     # Cambiar textura con la S
     # Cambiar color con el 2
     # Cambiar grosor con la G
     # Salir con ESC
     
    while True:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit(); sys.exit()
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_a: 
                    if juego.estado == "apagado":
                        
                        juego.tecla_a_presionada = True
                        juego.iniciar_animacion()
                    elif juego.estado == "prendido":
                        
                        juego.iniciar_apagado()
                elif event.key == pygame.K_s:
                    juego.cambiar_textura()
                elif event.key == pygame.K_2:
                    juego.cambiar_color()
                elif event.key == pygame.K_g:
                    juego.cambiar_grosor()
                elif event.key == pygame.K_ESCAPE:  
                    pygame.quit()
                    sys.exit()
            
            # Estoy en la animacion de estatica hasta que suelte la A
            
            elif event.type == pygame.KEYUP:
                if event.key == pygame.K_a:
                    
                    juego.tecla_a_presionada = False
                    if juego.estado == "animando":
                        juego.detener_animacion()

        
        if juego.estado == "animando" and not juego.tecla_a_presionada:
            juego.detener_animacion()

        juego.update()
        pygame.display.flip()
        clock.tick(60)


if __name__ == "__main__":
    main()