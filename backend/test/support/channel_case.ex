defmodule MessageAppWeb.ChannelCase do
  @moduledoc """
  This module defines the test case to be used by
  channel tests.

  It sets up the SQL sandbox for transactional tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Phoenix.ChannelTest
      import MessageApp.Factory

      @endpoint MessageAppWeb.Endpoint
    end
  end

  setup tags do
    MessageApp.DataCase.setup_sandbox(tags)
    :ok
  end
end
