defmodule Kadena.Chainweb.Client.CannedBlockPayloadRequests do
  @moduledoc false

  alias Kadena.Chainweb.Error
  alias Kadena.Test.Fixtures.Chainweb

  def request(
        :get,
        "https://api.testnet.chainweb.com/chainweb/0.0/testnet04/chain/0/payload/R_CYH-5qSKnB9eLlXply7DRFdPUoAF02VNKU2uXR8_0",
        _headers,
        _body,
        _options
      ) do
    response = Chainweb.fixture("block_payload_hash_retrieve")
    {:ok, response}
  end

  def request(
        :get,
        "https://api.testnet.chainweb.com/chainweb/0.0/testnet04/chain/0/payload/invalid",
        _headers,
        _body,
        _options
      ) do
    response =
      Error.new(
        {:chainweb,
         %{
           status: 400,
           title: "DecodeException \"not enough bytes\""
         }}
      )

    {:error, response}
  end

  def request(
        :get,
        "https://api.chainweb.com/chainweb/0.0/mainnet01/chain/20/payload/R_CYH-5qSKnB9eLlXply7DRFdPUoAF02VNKU2uXR8_0",
        _headers,
        _body,
        _options
      ) do
    response =
      Error.new(
        {:chainweb,
         %{
           status: 404,
           title: "not found"
         }}
      )

    {:error, response}
  end

  def request(
        :get,
        "https://api.testnet.chainweb.com/chainweb/0.0/testnet04/chain/0/payload/M4doD-jMHyxi4TvfBDUy3x9VMkcLxgnpjtvbbd77777",
        _headers,
        _body,
        _options
      ) do
    response =
      Error.new(
        {:chainweb,
         %{
           status: 404,
           title:
             "{\"reason\":\"key not found\",\"key\":\"M4doD-jMHyxi4TvfBDUy3x9VMkcLxgnpjtvbbd77774\"}"
         }}
      )

    {:error, response}
  end

  def request(
        :get,
        "https://col1.chainweb.com/chainweb/0.0/mainnet01/chain/0/payload/R_CYH-5qSKnB9eLlXply7DRFdPUoAF02VNKU2uXR8_0",
        _headers,
        _body,
        _options
      ) do
    response =
      Error.new(
        {:chainweb,
         %{
           status: :network_error,
           title: :nxdomain
         }}
      )

    {:error, response}
  end
end

defmodule Kadena.Chainweb.P2P.BlockPayloadTest do
  @moduledoc """
  `BlockPayload` endpoints implementation tests.
  """

  use ExUnit.Case

  alias Kadena.Chainweb.Client.CannedBlockPayloadRequests
  alias Kadena.Chainweb.Error
  alias Kadena.Chainweb.P2P.{BlockPayload, BlockPayloadResponse}

  describe "retrieve/1" do
    setup do
      Application.put_env(:kadena, :http_client_impl, CannedBlockPayloadRequests)

      on_exit(fn ->
        Application.delete_env(:kadena, :http_client_impl)
      end)

      success_response =
        {:ok,
         %BlockPayloadResponse{
           miner_data:
             "eyJhY2NvdW50IjoidXMxIiwicHJlZGljYXRlIjoia2V5cy1hbGwiLCJwdWJsaWMta2V5cyI6WyJkYjc3Njc5M2JlMGZjZjhlNzZjNzViZGIzNWEzNmU2N2YyOTgxMTFkYzYxNDVjNjY2OTNiMDEzMzE5MmUyNjE2Il19",
           outputs_hash: "Ph2jHKpKxXh5UFOfU7L8_Zb-8I91WlQtCzfn6UTC5cU",
           payload_hash: "R_CYH-5qSKnB9eLlXply7DRFdPUoAF02VNKU2uXR8_0",
           transactions: [],
           transactions_hash: "AvpbbrgkfNtMI6Hq0hJWZatbwggEKppNYL5rAXJakrw"
         }}

      %{
        payload_hash: "R_CYH-5qSKnB9eLlXply7DRFdPUoAF02VNKU2uXR8_0",
        non_exisitent_payload_hash: "M4doD-jMHyxi4TvfBDUy3x9VMkcLxgnpjtvbbd77777",
        success_response: success_response
      }
    end

    test "success", %{
      success_response: success_response,
      payload_hash: payload_hash
    } do
      ^success_response = BlockPayload.retrieve(payload_hash)
    end

    test "error with an non existing payload_hash", %{
      non_exisitent_payload_hash: non_exisitent_payload_hash
    } do
      {:error,
       %Kadena.Chainweb.Error{
         status: 404,
         title:
           "{\"reason\":\"key not found\",\"key\":\"M4doD-jMHyxi4TvfBDUy3x9VMkcLxgnpjtvbbd77774\"}"
       }} = BlockPayload.retrieve(non_exisitent_payload_hash)
    end

    test "error with an invalid payload_hash" do
      {:error, %Kadena.Chainweb.Error{status: 400, title: "DecodeException \"not enough bytes\""}} =
        BlockPayload.retrieve("invalid")
    end

    test "error with an invalid chain_id", %{payload_hash: payload_hash} do
      {:error, %Error{status: 404, title: "not found"}} =
        BlockPayload.retrieve(payload_hash, network_id: :mainnet01, chain_id: "20")
    end

    test "error with a non existing location", %{payload_hash: payload_hash} do
      {:error, %Error{status: :network_error, title: :nxdomain}} =
        BlockPayload.retrieve(payload_hash, location: "col1", network_id: :mainnet01)
    end
  end
end