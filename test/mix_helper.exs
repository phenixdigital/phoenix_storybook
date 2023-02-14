# https://github.com/phoenixframework/phoenix/blob/master/installer/test/mix_helper.exs
Mix.shell(Mix.Shell.Process)

defmodule PhxLiveStorybook.MixHelper do
  import ExUnit.Assertions

  def tmp_path, do: Path.expand("../tmp", __DIR__)

  def in_tmp_project(which, function) do
    conf_before = Application.get_env(:phoenix, :generators) || []
    tmp_dir = Path.join([tmp_path(), random_string(10)])
    path = Path.join([tmp_dir, to_string(which)])

    try do
      File.rm_rf!(path)
      File.mkdir_p!(path)
      File.cd!(path, function)
    after
      File.rm_rf!(tmp_dir)
      Application.put_env(:phoenix, :generators, conf_before)
    end
  end

  defp random_string(len) do
    len |> :crypto.strong_rand_bytes() |> Base.encode64() |> binary_part(0, len)
  end

  def assert_file(file) do
    assert File.regular?(file), "Expected #{file} to exist, but does not"
  end

  def assert_file(file, match) do
    cond do
      is_list(match) ->
        assert_file(file, &Enum.each(match, fn m -> assert &1 =~ m end))

      is_binary(match) or is_struct(match, Regex) ->
        assert_file(file, &assert(&1 =~ match))

      is_function(match, 1) ->
        assert_file(file)
        match.(File.read!(file))

      true ->
        raise inspect({file, match})
    end
  end
end
