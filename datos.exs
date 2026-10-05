# Integrantes: [Nombre 1], [Nombre 2], [Nombre 3]

# DATOS DE PRUEBA EXHAUSTIVOS: 13 confeccionistas (6 con alquiler), 4 lineas,
# 90 lotes (80 validos en los 6 dias + 10 invalidos, 2 por cada motivo de rechazo).
# Ver resultados_esperados.md para comprobar la salida del programa.
defmodule Datos do
  def confeccionistas do
    [
      %{codigo: "C01", nombre: "María Elena Ríos", alquiler: true},
      %{codigo: "C02", nombre: "Andrés Salazar", alquiler: false},
      %{codigo: "C03", nombre: "Luz Marina Gómez", alquiler: true},
      %{codigo: "C04", nombre: "Carlos Arturo Vélez", alquiler: false},
      %{codigo: "C05", nombre: "Diana Patricia Ospina", alquiler: true},
      %{codigo: "C06", nombre: "Julián Restrepo", alquiler: false},
      %{codigo: "C07", nombre: "Sandra Milena Cardona", alquiler: true},
      %{codigo: "C08", nombre: "Hernán Duque", alquiler: false},
      %{codigo: "C09", nombre: "Paola Andrea Londoño", alquiler: true},
      %{codigo: "C10", nombre: "Jhon Fredy Quintero", alquiler: false},
      %{codigo: "C11", nombre: "Yaneth Ramírez", alquiler: false},
      %{codigo: "C12", nombre: "Gloria Inés Marín", alquiler: true},
      %{codigo: "C13", nombre: "Fabio Arango", alquiler: false}
    ]
  end

  def lineas do
    [
      %{id: "L1", nombre: "Línea Norte", puestos: 6},
      %{id: "L2", nombre: "Línea Central", puestos: 4},
      %{id: "L3", nombre: "Línea Sur", puestos: 5},
      %{id: "L4", nombre: "Línea Oriente", puestos: 3}
    ]
  end

  def lotes do
    [
      # ---------- Dia 1 ----------
      %{confeccionista: "C04", linea: "L1", dia: 1, prendas: 60, defectos: 1},
      %{confeccionista: "C06", linea: "L2", dia: 1, prendas: 62, defectos: 3.5},
      %{confeccionista: "C05", linea: "L1", dia: 1, prendas: 29, defectos: 4.5},
      %{confeccionista: "C03", linea: "L2", dia: 1, prendas: 25, defectos: 0},
      %{confeccionista: "C09", linea: "L2", dia: 1, prendas: 53, defectos: 15},
      %{confeccionista: "C10", linea: "L2", dia: 1, prendas: 50, defectos: 1},
      %{confeccionista: "C05", linea: "L1", dia: 1, prendas: 42, defectos: 4.5},
      %{confeccionista: "C07", linea: "L3", dia: 1, prendas: 37, defectos: 5},
      %{confeccionista: "C07", linea: "L1", dia: 1, prendas: 50, defectos: 15},
      %{confeccionista: "C01", linea: "L2", dia: 1, prendas: 55, defectos: 7},
      %{confeccionista: "C01", linea: "L1", dia: 1, prendas: 70, defectos: 1.5},
      %{confeccionista: "C07", linea: "L2", dia: 1, prendas: 62, defectos: 4.5},
      %{confeccionista: "C07", linea: "L3", dia: 1, prendas: 60, defectos: 3},
      %{confeccionista: "C02", linea: "L1", dia: 1, prendas: 150, defectos: 1},
      %{confeccionista: "C07", linea: "L1", dia: 1, prendas: 110, defectos: 2},
      # ---------- Dia 2 ----------
      %{confeccionista: "C07", linea: "L2", dia: 2, prendas: 45, defectos: 4.5},
      %{confeccionista: "C03", linea: "L3", dia: 2, prendas: 45, defectos: 2},
      %{confeccionista: "C04", linea: "L2", dia: 2, prendas: 75, defectos: 1},
      %{confeccionista: "C09", linea: "L2", dia: 2, prendas: 41, defectos: 2},
      %{confeccionista: "C08", linea: "L4", dia: 2, prendas: 70, defectos: 6},
      %{confeccionista: "C05", linea: "L1", dia: 2, prendas: 70, defectos: 3},
      %{confeccionista: "C09", linea: "L3", dia: 2, prendas: 60, defectos: 4},
      %{confeccionista: "C07", linea: "L4", dia: 2, prendas: 63, defectos: 2},
      %{confeccionista: "C01", linea: "L1", dia: 2, prendas: 90, defectos: 12},
      %{confeccionista: "C03", linea: "L2", dia: 2, prendas: 21, defectos: 4},
      %{confeccionista: "C09", linea: "L4", dia: 2, prendas: 59, defectos: 5},
      %{confeccionista: "C03", linea: "L4", dia: 2, prendas: 23, defectos: 5},
      %{confeccionista: "C08", linea: "L2", dia: 2, prendas: 120, defectos: 5},
      %{confeccionista: "C02", linea: "L2", dia: 2, prendas: 20, defectos: 12},
      %{confeccionista: "C05", linea: "L2", dia: 2, prendas: 50, defectos: 2},
      %{confeccionista: "C08", linea: "L2", dia: 2, prendas: 25, defectos: 15},
      # ---------- Dia 3 ----------
      %{confeccionista: "C03", linea: "L4", dia: 3, prendas: 35, defectos: 2.01},
      %{confeccionista: "C08", linea: "L3", dia: 3, prendas: 95, defectos: 3},
      %{confeccionista: "C03", linea: "L1", dia: 3, prendas: 1, defectos: 0.5},
      %{confeccionista: "C03", linea: "L2", dia: 3, prendas: 29, defectos: 15},
      %{confeccionista: "C10", linea: "L1", dia: 3, prendas: 30, defectos: 1},
      %{confeccionista: "C07", linea: "L3", dia: 3, prendas: 25, defectos: 11},
      %{confeccionista: "C09", linea: "L1", dia: 3, prendas: 31, defectos: 5},
      %{confeccionista: "C11", linea: "L2", dia: 3, prendas: 40, defectos: 0},
      %{confeccionista: "C09", linea: "L3", dia: 3, prendas: 25, defectos: 2},
      %{confeccionista: "C06", linea: "L1", dia: 3, prendas: 95, defectos: 4},
      %{confeccionista: "C04", linea: "L3", dia: 3, prendas: 50, defectos: 1},
      # ---------- Dia 4 ----------
      %{confeccionista: "C06", linea: "L1", dia: 4, prendas: 35, defectos: 3.5},
      %{confeccionista: "C07", linea: "L1", dia: 4, prendas: 46, defectos: 4.5},
      %{confeccionista: "C08", linea: "L2", dia: 4, prendas: 40, defectos: 1.5},
      %{confeccionista: "C05", linea: "L4", dia: 4, prendas: 30, defectos: 10.01},
      %{confeccionista: "C03", linea: "L1", dia: 4, prendas: 55, defectos: 5},
      %{confeccionista: "C02", linea: "L3", dia: 4, prendas: 10, defectos: 15},
      %{confeccionista: "C05", linea: "L1", dia: 4, prendas: 48, defectos: 7},
      %{confeccionista: "C07", linea: "L4", dia: 4, prendas: 60, defectos: 4},
      %{confeccionista: "C04", linea: "L4", dia: 4, prendas: 90, defectos: 1},
      %{confeccionista: "C07", linea: "L2", dia: 4, prendas: 80, defectos: 2},
      %{confeccionista: "C05", linea: "L2", dia: 4, prendas: 57, defectos: 2},
      %{confeccionista: "C05", linea: "L4", dia: 4, prendas: 48, defectos: 1.5},
      # ---------- Dia 5 ----------
      %{confeccionista: "C09", linea: "L2", dia: 5, prendas: 66, defectos: 10},
      %{confeccionista: "C09", linea: "L1", dia: 5, prendas: 180, defectos: 3},
      %{confeccionista: "C04", linea: "L1", dia: 5, prendas: 40, defectos: 1},
      %{confeccionista: "C09", linea: "L2", dia: 5, prendas: 20, defectos: 5},
      %{confeccionista: "C03", linea: "L3", dia: 5, prendas: 23, defectos: 10},
      %{confeccionista: "C10", linea: "L4", dia: 5, prendas: 70, defectos: 1},
      %{confeccionista: "C11", linea: "L3", dia: 5, prendas: 45, defectos: 0.5},
      %{confeccionista: "C06", linea: "L2", dia: 5, prendas: 52, defectos: 3},
      %{confeccionista: "C05", linea: "L4", dia: 5, prendas: 58, defectos: 11},
      %{confeccionista: "C03", linea: "L1", dia: 5, prendas: 49, defectos: 3},
      %{confeccionista: "C03", linea: "L2", dia: 5, prendas: 65, defectos: 5.01},
      %{confeccionista: "C03", linea: "L3", dia: 5, prendas: 43, defectos: 15},
      %{confeccionista: "C07", linea: "L4", dia: 5, prendas: 42, defectos: 3},
      %{confeccionista: "C06", linea: "L2", dia: 5, prendas: 60, defectos: 2.5},
      %{confeccionista: "C05", linea: "L3", dia: 5, prendas: 51, defectos: 3},
      %{confeccionista: "C05", linea: "L3", dia: 5, prendas: 1, defectos: 8},
      # ---------- Dia 6 ----------
      %{confeccionista: "C06", linea: "L1", dia: 6, prendas: 57, defectos: 2.5},
      %{confeccionista: "C07", linea: "L1", dia: 6, prendas: 90, defectos: 4},
      %{confeccionista: "C06", linea: "L3", dia: 6, prendas: 26, defectos: 6},
      %{confeccionista: "C07", linea: "L3", dia: 6, prendas: 130, defectos: 1},
      %{confeccionista: "C03", linea: "L3", dia: 6, prendas: 40, defectos: 10},
      %{confeccionista: "C05", linea: "L2", dia: 6, prendas: 50, defectos: 100},
      %{confeccionista: "C08", linea: "L4", dia: 6, prendas: 61, defectos: 6},
      %{confeccionista: "C08", linea: "L4", dia: 6, prendas: 34, defectos: 4},
      %{confeccionista: "C07", linea: "L2", dia: 6, prendas: 45, defectos: 4},
      %{confeccionista: "C08", linea: "L1", dia: 6, prendas: 67, defectos: 3},
      # ---------- Lotes con errores de digitacion (10) ----------
      %{confeccionista: "C99", linea: "L1", dia: 9, prendas: 500, defectos: 150},  # esperado: confeccionista_desconocido  (ademas dia, prendas y % malos: solo se informa el 1.o)
      %{confeccionista: "c01", linea: "L2", dia: 2, prendas: 60, defectos: 3},  # esperado: confeccionista_desconocido  (minuscula: los codigos distinguen mayusculas)
      %{confeccionista: "C03", linea: "L9", dia: 1, prendas: 50, defectos: 2},  # esperado: linea_desconocida
      %{confeccionista: "C05", linea: "l1", dia: 8, prendas: 300, defectos: -1},  # esperado: linea_desconocida  (ademas dia, prendas y % malos)
      %{confeccionista: "C13", linea: "L1", dia: 0, prendas: 50, defectos: 2},  # esperado: dia_invalido
      %{confeccionista: "C08", linea: "L2", dia: 3.0, prendas: 400, defectos: 200},  # esperado: dia_invalido  (3.0 es decimal, no entero; ademas prendas y % malos)
      %{confeccionista: "C07", linea: "L3", dia: 4, prendas: 181, defectos: 2},  # esperado: prendas_fuera_de_rango  (181 = un paso sobre el maximo)
      %{confeccionista: "C09", linea: "L4", dia: 5, prendas: 62.5, defectos: 120},  # esperado: prendas_fuera_de_rango  (62.5 no es entero; ademas % malo)
      %{confeccionista: "C10", linea: "L1", dia: 6, prendas: 45, defectos: 100.5},  # esperado: porcentaje_invalido  (100.5 > 100)
      %{confeccionista: "C04", linea: "L2", dia: 2, prendas: 55, defectos: -0.5}  # esperado: porcentaje_invalido  (negativo)
    ]
  end
end
