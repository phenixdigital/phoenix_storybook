defmodule PhoenixStorybook.TemplateHelpersTest do
  use ExUnit.Case, async: true

  import PhoenixStorybook.TemplateHelpers

  test "set_variation_dom_id/2" do
    template =
      set_variation_dom_id(
        """
        <div id=":variation_id">
          <.psb-variation phx-click={JS.push("assign", value: %{foo: "bar"})}/>
          <.psb-variation phx-click={JS.push("toggle", value: %{attr: :foo})}/>
        </div>
        """,
        "component-hello-world"
      )
      |> set_js_push_variation_id({:single, :hello_world})

    assert template == """
           <div id="component-hello-world">
             <.psb-variation phx-click={JS.push("assign", value: %{foo: "bar", variation_id: [:single, :hello_world]})}/>
             <.psb-variation phx-click={JS.push("toggle", value: %{attr: :foo, variation_id: [:single, :hello_world]})}/>
           </div>
           """
  end

  test "variation_template?/1" do
    assert variation_template?("<div><.psb-variation/></div>")
    assert variation_template?("<div><.psb-variation  /></div>")
    assert variation_template?("<div><.psb-variation whatever /></div>")

    assert variation_template?("""
           <div>
             <.psb-variation/>
           </div>
           """)

    refute variation_template?("<div><variation/></div>")
    refute variation_template?("<div><.psb-variation-group/></div>")
  end

  test "variation_group_template?/1" do
    assert variation_group_template?("<div><.psb-variation-group/></div>")
    assert variation_group_template?("<div><.psb-variation-group  /></div>")
    assert variation_group_template?("<div><.psb-variation-group whatever /></div>")

    assert variation_group_template?("""
           <div>
             <.psb-variation-group/>
           </div>
           """)

    refute variation_group_template?("<div><variation-group/></div>")
    refute variation_group_template?("<div><.psb-variation/></div>")
  end

  test "replace_template_variation/2" do
    heex =
      replace_template_variation(
        """
        <div>
          <.psb-variation/>
        </div>
        """,
        "<span/>"
      )

    assert heex == """
           <div>
             <span/>
           </div>
           """
  end

  test "replace_template_variation/2 with indentation" do
    heex =
      replace_template_variation(
        """
        <div>
          <div>
            <.psb-variation/>
          </div>
        </div>
        """,
        """
        <span>
          <span>
            hello
          </span>
        </span>
        """,
        _indent = true
      )

    assert heex == """
           <div>
             <div>
               <span>
                 <span>
                   hello
                 </span>
               </span>
             </div>
           </div>
           """
  end

  test "replace_template_variation_group/2" do
    heex =
      replace_template_variation_group(
        """
        <div>
          <.psb-variation-group/>
        </div>
        """,
        "<span/>"
      )

    assert heex == """
           <div>
             <span/>
           </div>
           """
  end

  test "code_hidden?/1" do
    assert code_hidden?("<div psb-code-hidden><.psb-variation/></div>")
    refute code_hidden?("<div><.psb-variation/></div>")
  end

  test "extract_placeholder_attributes/2" do
    assert extract_placeholder_attributes("<span/>") == ""
    assert extract_placeholder_attributes("<.psb-variation/>") == ""
    assert extract_placeholder_attributes("<.psb-variation-group/>") == ""
    assert extract_placeholder_attributes(~s|<.psb-variation foo="bar"/>|) == ~s|foo="bar"|

    assert extract_placeholder_attributes(~s|<.psb-variation-group form={f} foo="bar"/>|) ==
             ~s|form={f} foo="bar"|

    assert extract_placeholder_attributes(~s|<.psb-variation label="foo" status={true}/>|) ==
             ~s|label="foo" status={true}|
  end

  test "extract_placeholder_attributes/2 with inspection" do
    assert extract_placeholder_attributes("<span/>", {"topic", :variation_id}) == ""
    assert extract_placeholder_attributes("<.psb-variation/>", {"topic", :variation_id}) == ""

    assert extract_placeholder_attributes("<.psb-variation-group/>", {"topic", :variation_id}) ==
             ""

    assert extract_placeholder_attributes(~s|<.psb-variation foo={f}/>|, {"topic", :variation_id}) ==
             ~s|foo={psb_inspect("topic", :variation_id, :foo, f)}|

    assert extract_placeholder_attributes(
             ~s|<.psb-variation foo={"bar"}/>|,
             {"topic", :variation_id}
           ) ==
             ~s|foo={psb_inspect("topic", :variation_id, :foo, "bar")}|

    assert extract_placeholder_attributes(
             ~s|<.psb-variation-group form={f} foo="bar"/>|,
             {"topic", :variation_id}
           ) ==
             ~s|form={psb_inspect("topic", :variation_id, :form, f)} foo={psb_inspect("topic", :variation_id, :foo, "bar")}|
  end
end
