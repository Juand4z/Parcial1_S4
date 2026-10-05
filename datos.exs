defmodule Datos do
  def confeccionistas do
    [
      %{codigo: "C01", nombre: "María Elena Ríos", alquiler: true},
      %{codigo: "C02", nombre: "Andrés Salazar", alquiler: false},
      %{codigo: "C03", nombre: "Sofia Salazar", alquiler: true},
      %{codigo: "C04", nombre: "Carmen Salazar", alquiler: false}
      # ...
    ]
  end

  def lineas do
    [
      %{id: "L1", nombre: "Línea Norte", puestos: 6},
      %{id: "L2", nombre: "Línea Sur", puestos: 4},
      %{id: "L3", nombre: "Línea Central", puestos: 8},
      %{id: "L4", nombre: "Línea Occidente", puestos: 2}
      # ...
    ]
  end

  def lotes do
    [
      %{confeccionista: "C01", linea: "L1", dia: 1, prendas: 70, defectos: 1.5},
      %{confeccionista: "C01", linea: "L2", dia: 1, prendas: 55, defectos: 7},
      %{confeccionista: "C02", linea: "L2", dia: 2, prendas: 55, defectos: 20},
      %{confeccionista: "C06", linea: "L2", dia: 3, prendas: 55, defectos: 6}
      # ...
    ]
  end
end
