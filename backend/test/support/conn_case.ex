defmodule MessageAppWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  It sets up the SQL sandbox for transactional tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import Phoenix.ConnTest
      import MessageApp.Factory

      @endpoint MessageAppWeb.Endpoint
    end
  end

  setup tags do
    MessageApp.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
