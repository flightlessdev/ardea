defmodule Ardea.Service.Http.Endpoint do
  @type __MODULE__ :: [
          method: :get | :post | :put,
          url: binary(),
          url_variables: [],
          query_params: map(),
          fixed_params: map(),
          headers: map()
        ]

  defstruct [
    :method,
    :url,
    :url_variables,
    :query_params,
    :fixed_params,
    :headers
  ]

  @url_placeholder "<placeholder>"
  @body_path "body"

  def validate(endpoints) do
    Enum.reduce(endpoints, %{}, fn {key, data}, acc -> Map.put(acc, key, validate_one(data)) end)
  end

  defp validate_one(data) do
    url = Map.fetch!(data, "url")
    method = get_method(data)
    query_params = Map.get(data, "query_params", %{})
    fixed_params = Map.get(data, "fixed_params", %{})
    url_variables = Map.get(data, "url_variables", [])
    headers = Map.get(data, "headers", %{})

    if length(String.split(url, @url_placeholder)) - 1 != length(url_variables) do
      raise Ardea.Configuration.ConfigError,
            "Number of url variables does not match url placeholders"
    end

    %__MODULE__{
      url: url,
      method: method,
      query_params: query_params,
      fixed_params: fixed_params,
      url_variables: url_variables,
      headers: headers
    }
  end

  defp get_method(%{"method" => "get"}), do: :get
  defp get_method(%{"method" => "put"}), do: :put
  defp get_method(%{"method" => "post"}), do: :post

  defp get_method(_), do: raise(Ardea.Configuration.ConfigError, "Invalid or missing http method")

  def make_request(
        %__MODULE__{
          url: url,
          method: method,
          url_variables: url_variables,
          query_params: query_params,
          fixed_params: fixed_params,
          headers: headers
        } = _endpoint,
        base_url,
        data
      ) do
    body = Map.get(data, @body_path, "")

    with {:ok, url} <- replace_path_vars(base_url <> url, url_variables, data),
         params <- set_query_params(query_params, fixed_params, data) do
      make_request(method, url, body, headers, params)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp replace_path_vars(url, url_variables, data) do
    mapped_url_variables = Enum.map(url_variables, &Map.get(data, &1))

    if Enum.member?(mapped_url_variables, nil) do
      {:error, "Could not map all url variables"}
    else
      {:ok,
       Enum.reduce(
         mapped_url_variables,
         url,
         &String.replace(&2, @url_placeholder, &1, global: false)
       )}
    end
  end

  defp set_query_params(query_params, fixed_params, data) do
    Map.merge(
      fixed_params,
      Enum.reduce(query_params, %{}, fn {k, p}, acc -> Map.put(acc, k, Map.get(data, p)) end)
    )
  end

  defp make_request(method, url, body, headers, params)

  defp make_request(method, url, body, headers, params)
       when is_map(body) and (method == :post or method == :put) do
    case Jason.encode(body) do
      {:ok, body} ->
        make_request(
          method,
          url,
          body,
          Map.put(headers, "Content-Type", "application/json"),
          params
        )

      _ ->
        {:error, "Failed to json encode body"}
    end
  end

  defp make_request(method, url, body, headers, params)
       when method == :post or method == :put do
    make_request(method, url, body, Map.put(headers, "Content-Type", "text/plain"), params)
  end

  defp make_request(method, url, body, headers, params) do
    with {:ok, %HTTPoison.Response{body: body, status_code: code}} <-
           HTTPoison.request(method, url, body, headers, params: params),
         :ok <- ok_response(code, body),
         {:ok, response} <- parse_body(body) do
      {:ok, response}
    else
      {:error, reason} -> {:error, reason}
      _ -> {:error, "Failed to send http request due to unhandled error."}
    end
  end

  defp ok_response(code, body) when code >= 400 or code < 0,
    do: {:error, "Got error response. Code: #{code}, body: #{inspect(body)}"}

  defp ok_response(_, _), do: :ok

  defp parse_body(body) do
    with {:ok, body} <- Jason.decode(body) do
      {:ok, body}
    else
      _ ->
        {:error, "Could not decode response body to json"}
    end
  end
end
