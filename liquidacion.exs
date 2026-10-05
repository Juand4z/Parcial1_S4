defmodule Liquidacion do
  def valor_lote(%{prendas: prendas, defectos: defectos}) do
    prendas * 32 * ajuste_defecto(defectos)
  end

  defp ajuste_defecto(defectos) when defectos <= 2, do: 107
  defp ajuste_defecto(defectos) when defectos > 2 and defectos <= 5, do: 100
  defp ajuste_defecto(defectos) when defectos > 5 and defectos <= 10, do: 88
  defp ajuste_defecto(_defectos), do: 75

  def bonificacion_del_dia(prendas_dia) do
    if prendas_dia >= 120 do
      18000
    else
      0
    end
  end

  def alquiler_maquina_descontable(%{alquiler: true}, dias) do
    dias * 15000
  end

  def alquiler_maquina_descontable(_confeccionista, _dias), do: 0

  def liquidar_confeccionista(confeccionista, lotes_validos) do
    detalle = #detalle representa un mapa que se define en la funcion detalle_del_dia() con diferentes claves que se ven en esa funcion
      lotes_validos
      |> Enum.group_by(fn lote -> lote.dia end) # Se agrupan por dia en otro mapa donde el dia representara la clave y un alista de lotes el valor
      |> Enum.sort_by(fn {dia, _lotes} -> dia end) #Se ordenan teniendo en cuenta el dia es decir cornologicamente
      |> Enum.map(fn {dia, lotes_del_dia} -> detalle_del_dia(dia, lotes_del_dia) end) #Paso el ultimo mapa obtenido a un Enum.map para pasar cada dia por la funcion detalle_del_dia()

    bruto = Enum.map(detalle, fn detalle_dia -> Map.get(detalle_dia, :valor_lotes) end) |> Enum.sum() #reprensenta el valor bruto de los lotes en un dia sumando el valor de los lotes del confeccionista sin importar el dia
    bonificaciones = Enum.map(detalle, fn detalle_dia -> Map.get(detalle_dia, :bonificacion) end) |> Enum.sum() #representa el valore de la bonificacion del confeccionista sumando 18k por cada dia que supere 120 prendas
    alquiler = alquiler_maquina_descontable(confeccionista, length(detalle)) #calcula cuanto fue el costo del alquiler para descontarselo luego al confeccionista

    %{
      codigo: confeccionista.codigo, #confeccionista es un mapa por eso se usa .codigo, .nombre, etc
      nombre: confeccionista.nombre,
      prendas: Enum.map(detalle, fn x -> Map.get(x, :prendas) end) |> Enum.sum(), #recorre la lista de mapas "detalle" para sumar las prendas de cada dia que tuvo un confeccionista
      bruto: bruto,
      bonificaciones: bonificaciones,
      alquiler: alquiler,
      neto: bruto + bonificaciones - alquiler,
      detalle: detalle
    }
  end

  defp detalle_del_dia(dia, lotes_del_dia) do
    prendas =
      Enum.map(lotes_del_dia, fn lote -> Map.get(lote, :prendas) end)
      |> Enum.sum()

    %{
      dia: dia,
      prendas: prendas,
      valor_lotes: lotes_del_dia |> Enum.map(fn x -> valor_lote(x) end) |> Enum.sum(),
      bonificacion: bonificacion_del_dia(prendas)
    }
  end

  def liquidar_todos(confeccionistas, lotes_validos) do #lotes validos entran como una lista de mapas
    grupos = Enum.group_by(lotes_validos, fn lote -> lote.confeccionista end) #crea un mapa con clave "el codigo del confeccionista" y valor "los lotes validos de ese confeccionista"

    confeccionistas
    |> Map.values() #convierte el mapa de confeccionistas en una lista para poder recorrerla
    |> Enum.sort_by(fn confeccionista -> confeccionista.codigo end) #recorre dicha lista para ordenarla segun el codigo del confeccionista
    |> Enum.map(fn confeccionista -> #liquida cada confeccionista, resultando una lista de mapas, siendo cada mapa los del confeccionista junto con los datos de su liquidacion
      liquidar_confeccionista(confeccionista, Map.get(grupos, confeccionista.codigo, [])) #se usar Map.get/3 para q en caso de que un confeccionista no halla trabajo o no tenga lotes validos, la variable lotes_validos no tome el valor de "nil", sino que le asigne una lista vacia "[]" para hacer las operaciones matematicas sin problemas como Enum.sum([]) = 0
    end)
  end
end
