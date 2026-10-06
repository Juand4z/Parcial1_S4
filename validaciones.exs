defmodule Validacion do
  @moduledoc """
  Módulo de validacion de lotes.
  Verifica las reglas de negocio (confeccionista, linea, dia, prendas y porcentaje de defectos),
  clasifica los lotes en validos e invalidos, y procesa el lote adicional ingresado por consola.
  - Autores: Luis Miguel Garcia Villanueva, Juan David Arias Sanchez.
  - Fecha: Octubre 5 2026
  - Licencia: GNU GPL v3
  """

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
    # usa patern matching para intentar comparar lo de la derecha con lo de la izquierda, en caso de ser posible continua con el siguiente
    with :ok <- verificar_confeccionista(lote, confeccionistas),
         # si no es posible retorna lo que sea que retorne el metodo de la derecha en este caso retornaria "{:error, :tipodeerror}
         :ok <- verificar_linea(lote, lineas),
         :ok <- verificar_dia(lote),
         :ok <- verificar_prendas(lote),
         :ok <- verificar_porcentaje_defectos(lote) do
      {:ok, lote}
    end
  end

  #clausula en caso de que datos tenga estructuras de datos erroneas
  def validar_lote(lote, _confeccionistas, _lineas) when not is_map(lote),
  do: {:error, :confeccionista_desconocido}

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
    # como los confeccionistas los converimos de lista de mapas a mapa con clave "codigo del confeccionista", podemos usar Map.has_key? para ver si ese lote si contiene un confeccionista que existe en los datos
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
    # las lineas tambien fueron indexadas para pasarlas de listas de mapas a mapa con clave "id de la lista" y valor la lista entera (un mapa)
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
    # obtener el valor que esta asociado a la clave ":dia" en el mapa "lote"
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

    if porcentaje >= 0 and porcentaje <= 100 do
      :ok
    else
      {:error, :porcentaje_invalido}
    end
  end

  @doc """
   Procesa una lista de lotes, los valida individualmente y los clasifica en validos o invalidos
    ## Retorna:
    - ':validos []' : Lista de mapas con los lotes que pasaron las verificaciones anteriores
    - ':invalidos []' : Lista de tuplas '{lote, motivo}' con los lotes rechazados y su error.
    Parametros:
    lotes : Lista de mapas que contiene los lotes (mapas) a validas.
    confeccionistas: Mapa que contiene los confeccionistas registrados.
    lineas: Mapa que contiene las lineas de produccion registradas.
  """
  def validar_lotes(lotes, confeccionistas, lineas) do
    # obtengo una lista con elementos conformados por una tupla con {el lote, {:ok, otra vez el lote}} o {el lote, {:error, el tipo de error}}
    validaciones =
      Enum.map(lotes, fn a ->
        {a, validar_lote(a, confeccionistas, lineas)}
      end)

    # se usa un reduce para acumular mediante un mapa los lotes validos e invalitos
    Enum.reduce(validaciones, %{validos: [], invalidos: []}, fn
      # existen tods funciones anonimas, una para almacenas los lotes validos en una lista y viceversa
      {_lote, {:ok, lote_valido}}, acc ->
        # se usa el operador "|" para insertar un elemento al mapa acumulador y la lista de lotes al valor de la clave del mapa acumulador
        %{acc | validos: [lote_valido | acc.validos]}

      # acc.validos lo que hace es que me trae la lista que ya existia desde antes,
      # para sumarle el nuevo lote valido ademas represneta que me trae el valor de la clave validos del mapa acc

      {lote, {:error, motivo}}, acc ->
        # lo mismo pero para los lotes invalidos
        %{acc | invalidos: [{lote, motivo} | acc.invalidos]}
    end)
  end

  # Funcion que convierte una cadena de texto en un mapa estrucurado
  #
  # ## Retorna:
  # - '{:ok, lote}' : Todos los parametros fueron convertidos y parseados correctamente
  # - '{:error, formato_invalido}' : Algun parametro no estaba escrito de manera valida
  #
  # ### Parametros:
  # - 'texto': Cadena de texto separando cada elemento con ';'
  #
  defp parsear_lote_adicional(texto) when is_binary(texto) do
    campos =
      texto
      |> String.trim()
      # me retorna una lista con los elementos que estaban separados por ";"
      |> String.split(";")
      # elimina los espacios al principio y al final de cada elemento de la lista
      |> Enum.map(fn x -> String.trim(x) end)

    # usa patern matching para asignarle un valor a cada variable de la izquierda
    with [confeccionista, linea, dia_texto, prendas_texto, defectos_texto] <- campos,
         # texto_a_entero retorna {:ok, entero} o :error, el dia debe ser un entero
         {:ok, dia} <- Util.texto_a_entero(dia_texto),
         # las prendas tambien deben ser un entero
         {:ok, prendas} <- Util.texto_a_entero(prendas_texto),
         # texto_a_numero acepta entero o decimal con punto; si algo falla retorna :error y el else devuelve {:error, :formato_invalido}
         {:ok, defectos} <- Util.texto_a_numero(defectos_texto) do
      # si todo pasa correctamente me retorna un tupla con {:ok, el nuevo lote}
      {:ok,
       %{
         confeccionista: confeccionista,
         linea: linea,
         dia: dia,
         prendas: prendas,
         defectos: defectos
       }}
    else
      # si no pasa el proceso correctamente retorna un error controladito
      _ -> {:error, :formato_invalido}
    end
  end

  # Funcion de respaldo para el proceso de parseo, captura cualquier otro argumento que no haya superado los guardas anteriores.
  # Retorna un error controlado con formato '{:error, :formato_invalido}'.
  # ## Parametros:
  # '_otro': Cualquier otro tipo de dato que no sea una cadena de texto.
  # en caso de que no cumpla la guard me retorna directamente el errorsito
  defp parsear_lote_adicional(_otro), do: {:error, :formato_invalido}

  @doc """
  Funcion que evalua si un lote se omite por falta da informacion añadida o se parsea segun la informacion añadida con la estructura case

  Retorna:
  - : omitido : No se escribe nada (espacio en blanco).
  - {:agregado, lote_valido} : Si el lote fue parceado y validado correctamente
  - {:rechazado, lote, :motivo} :Si no cumple con las condiciones esperadas.

  Parametros:
  - 'texto' : Cadena de texto con los datos del lote a evaluar.
  - ' confeccionistas' : Mapa con los confeccionistas verificados y validados.
  - 'lineas' : Mapacon las lineas verificadas y validadas.
  """
  def evaluar_lote_adicional(texto, confeccionistas, lineas) do
    case String.trim(texto) do
      # en caso de que no escriba nada retorna :omitido para hacer saber que no se ingreso un nuevo lote
      "" ->
        :omitido

      contenido ->
        # patern matching para asignar el mapa a la variable "lote"
        with {:ok, lote} <- parsear_lote_adicional(contenido) do
          # se usa case para determinar si el lote es valido o es rechazado
          case validar_lote(lote, confeccionistas, lineas) do
            {:ok, lote_valido} -> {:agregado, lote_valido}
            {:error, motivo} -> {:rechazado, lote, motivo}
          end
        end
    end
  end
end
