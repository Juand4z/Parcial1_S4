defmodule Liquidacion do
  def valor_lote(%{prendas: prendas, defectos: defectos}) do
    prendas * 3200 * ajuste_defecto(defectos)
  end

  defp ajuste_defecto(defectos) when defectos <= 2, do: 1.07
  defp ajuste_defecto(defectos) when defectos > 2 and defectos <= 5, do: 1
  defp ajuste_defecto(defectos) when defectos > 5 and defectos <= 10, do: 0.88
  defp ajuste_defecto(_defectos), do: 0.75

  def bonificacion_del_dia(prendas_dia) do
    if prendas_dia >= 120 do
      18000
    else
      0
    end
  end

  def alquiler_maquina_descontable(%{alquiler: true}, dias) do
    dias * 18000
  end

  def alquiler_maquina_descontable(_confeccionista, _dias), do: 0

  def liquidar_confeccionista(confeccionista, lotes_validos) do
    detalle =
      lotes_validos
      |> Enum.group_by(fn lote -> lote.dia end)
      |> Enum.sort_by(fn {dia, _lotes} -> dia end)
      |> Enum.map(fn {dia, lotes_del_dia} -> detalle_del_dia(dia, lotes_del_dia) end)

    bruto = Enum.map(detalle, fn detalle_dia -> Map.get(detalle_dia, :valor_lotes) end) |> Enum.sum()
    bonificaciones = Enum.map(detalle, fn detalle_dia -> Map.get(detalle_dia, :bonificacion) end) |> Enum.sum()
    alquiler = descuento_alquiler(confeccionista, length(detalle))

    %{
      codigo: confeccionista.codigo,
      nombre: confeccionista.nombre,
      prendas: Enum.map(detalle, fn x -> Map.get(x, :prendas) end) |> Enum.sum(),
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

  def liquidar_todos(confeccionistas, lotes_validos) do
    grupos = Enum.group_by(lotes_validos, fn lote -> lote.confeccionista end)

    confeccionistas
    |> Map.values()
    |> Enum.sort_by(fn confeccionista -> confeccionista.codigo end)
    |> Enum.map(fn confeccionista ->
      liquidar_confeccionista(confeccionista, Map.get(grupos, confeccionista.codigo, []))
    end)
  end
end
