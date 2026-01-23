defmodule PhoenixStorybook.PlaygroundPreviewLiveTest do
  use ExUnit.Case, async: true

  alias Phoenix.LiveView.Socket
  alias PhoenixStorybook.Story.PlaygroundPreviewLive

  defmodule HandleInfoStory do
    def handle_info({:storybook_handle_info, from}, socket) do
      send(from, :handled)
      {:noreply, socket}
    end
  end

  test "handle_info delegates to story when defined" do
    socket = %Socket{assigns: %{story: HandleInfoStory}}

    assert {:noreply, ^socket} =
             PlaygroundPreviewLive.handle_info({:storybook_handle_info, self()}, socket)

    assert_receive :handled
  end
end
