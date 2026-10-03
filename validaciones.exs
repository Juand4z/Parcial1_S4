defmodule Validacion do

  def validar_lote(lote, confeccionistas, lineas) do
    with :ok <- verificar_confeccionista(lote, confeccionistas),
         :ok <- verificar_linea(lote, lineas),
         :ok <- verificar_dia(lote),
         :ok <- verificar_prendas(lote),
         :ok <- verificar_porcentaje_defectos(lote) do
      {:ok, lote}
    end
  end

  defp verificar_confeccionista(lote, confeccionistas) do
    if Map.has_key?(confeccionistas, Map.get(lote, :confeccionista)) do
      :ok
    else
      {:error, :confeccionista_desconocido}
    end
  end

  defp verificar_linea(lote, lineas) do
    if Map.has_key?(lineas, Map.get(lote, :linea)) do
      :ok
    else
      {:error, :linea_desconocida}
    end
  end

  defp verificar_dia(lote) do
    dia = Map.get(lote, :dia)

    if dia > 0 and dia < 7 and is_integer(dia) do
      :ok
    else
      {:error, :dia_invalido}
    end
  end

  defp verificar_prendas(lote) do
    prendas = Map.get(lote, :prendas)

    if prendas > 0 and prendas < 181 and is_integer(prendas) do
      :ok
    else
      {:error, :prendas_fuera_de_rango}
    end
  end

  defp verificar_porcentaje_defectos(lotes) do
    porcentaje = Map.get(lotes, :defectos)

    if porcentaje >= 0 and porcentaje < 101 do
      :ok
    else
      {:error, :porcentaje_invalido}
    end
  end

  def validar_lotes(lotes, confeccionistas, lineas) do
    validaciones =
      Enum.map(lotes, fn a ->
        {a, validar_lote(a, confeccionistas, lineas)}
      end)

    validos =
      Enum.reduce(validaciones, %{validos: [], invalidos: []}, fn
        {_lote, {:ok, lote_valido}}, acc ->
          %{acc | validos: [lote_valido | acc.validos]}
          # accvalidos lo que hace es que me trae la lista que ya existia desde antes,
          # para sumarle el nuevo lot ademas represneta que me trae el valor de la clave validos del mapa acc

        {lote, {:error, motivo}}, acc ->
          %{acc | invalidos: [{lote, motivo} | acc.invalidos]}
      end)
  end
end

