defmodule Validacion do
  @doc """
  Valida las reglas de negocio de un lote de manera secuencial con la estructura "with".
  Evalua cada condicion en order y se detiene cuando se encuentra con un error:
  - Retorna la tupla '{:ok, lote}' si cumple con todas las verificaciones.
  - Retorna la tupla '{:error, motivo}' si falla en alguna verificacion delvolviendo el motivo de este.
  ## Parametros
  - lote : Mapa con la informacion de los lotes a verificar
  - confeccionistas : Mapa con los confeccionistas registrados para verificar su existencia.
  - lineas: Mapa de lineas de produccion para verificar su existencia.
  """
  def validar_lote(lote, confeccionistas, lineas) do
    with :ok <- verificar_confeccionista(lote, confeccionistas),
         :ok <- verificar_linea(lote, lineas),
         :ok <- verificar_dia(lote),
         :ok <- verificar_prendas(lote),
         :ok <- verificar_porcentaje_defectos(lote) do
      {:ok, lote}
    end
  end

# Verifica si el confeccionista asignado a un lote existe en la coleccion de confeccionistas.
#
# ## Retorna:
# - '.ok' si la clave del confeccionista existe en el mapa.
# - '{:error, :confeccionista_desconocido}' si el confeccionista no existe.
#
# ### Parametros:
# - 'lote': Mapa que contiene la informacion del lote el cual requiere la clave ':confeccionistas'.
# - 'confeccionista': Mapa que contiene el codigo de los usando el código de confeccionista como clave.
  defp verificar_confeccionista(lote, confeccionistas) do
    if Map.has_key?(confeccionistas, Map.get(lote, :confeccionista)) do
      :ok
    else
      {:error, :confeccionista_desconocido}
    end
  end

# Verifica si la línea asignada a un lote existe dentro de la colección de líneas.
#
# ## Retorna:
# - ':ok' si la clave de la línea existe en el mapa.
# - '{:error, :linea_desconocida}' si la línea no existe.
#
# ### Parámetros:
# - 'lote': Mapa que contiene la información del lote el cual requiere la clave ':linea'
# - 'lineas': Mapa que contiene los datos de las líneas registradas, usando el código de línea como clave.
  defp verificar_linea(lote, lineas) do
    if Map.has_key?(lineas, Map.get(lote, :linea)) do
      :ok
    else
      {:error, :linea_desconocida}
    end
  end

# Verifica si el dia esta dentro del rango valido
#
# ## Retorna:
# - ':ok' si el dia esta dentro de el rango permitido (1 a 6).
# - '{:error, :dia_invalido}' si el dia es mayor o igual 7 o menor o igual a 0.
#
# ### Parámetros:
# - 'lote': Mapa que contiene la información del lote el cual requiere la clave ':dia'.
  defp verificar_dia(lote) do
    dia = Map.get(lote, :dia)

    if dia > 0 and dia < 7 and is_integer(dia) do
      :ok
    else
      {:error, :dia_invalido}
    end
  end

# Verifica si las prendas estan dentro del rango valido.
#
# ## Retorna:
# - ':ok' si las prendas son mayores que 0 y menores que 181 (rango de 1 a 180).
# - '{:error, :prendas_fuera_de_rango}' si se ingresa un valor menor que 0, mayor o igual a 181 o un valor que no sea un entero.
#
# ### Parámetros:
# - 'lote': Mapa que contiene la información del lote el cual requiere la clave ':prendas'.
  defp verificar_prendas(lote) do
    prendas = Map.get(lote, :prendas)

    if prendas > 0 and prendas < 181 and is_integer(prendas) do
      :ok
    else
      {:error, :prendas_fuera_de_rango}
    end
  end

# Verifica si el porcentaje de defectos se encuentra en el rango valido.
#
# ## Retorna:
# - ':ok' si se encuentran en el rango de 0 a 100.
# - '{:error, :porcentaje_invalido}' si se ingresa un valor menor a 0 o mayor a 100.
#
# ### Parámetros:
# - 'lotes': Mapa que contiene la información de los lotes el cual requiere de las claves ':defectos'.
  defp verificar_porcentaje_defectos(lotes) do
    porcentaje = Map.get(lotes, :defectos)

    if porcentaje >= 0 and porcentaje < 101 do
      :ok
    else
      {:error, :porcentaje_invalido}
    end
  end

@doc'''

'''
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

  defp parsear_lote_adicional(texto) when is_binary(texto) do
    campos = texto
    |> String.split(";")
    |> Enum.map(fn x -> String.trim(x) end)

    with [confeccionista, linea, dia_texto, prendas_texto, defectos_texto] <- campos,
         {:ok, dia} <- Util.texto_a_numero(dia_texto),
         {:ok, prendas} <- Util.texto_a_numero(prendas_texto),
         {:ok, defectos} <- Util.texto_a_numero(defectos_texto) do
      {:ok,
       %{
         confeccionista: confeccionista,
         linea: linea,
         dia: dia,
         prendas: prendas,
         defectos: defectos
       }}
    else
      _ -> {:error, :formato_invalido}
    end
  end

  defp parsear_lote_adicional(_otro), do: {:error, :formato_invalido}

  def evaluar_lote_adicional(texto, confeccionistas, lineas) do
    case String.trim(texto) do
      "" ->  :omitido

      contenido ->
        with {:ok, lote} <- parsear_lote_adicional(contenido) do
          case validar_lote(lote, confeccionistas, lineas) do
            {:ok, lote_valido} -> {:agregado, lote_valido}
            {:error, motivo} -> {:rechazado, lote, motivo}
          end
        end
    end
  end
end
