defmodule PhxLiveStorybook.TemplateHelpersTest do
  use ExUnit.Case, async: true

  import PhxLiveStorybook.TemplateHelpers

  test "set_template_id/2" do
    template =
      set_template_id(
        """
        <div id=":story_id">
          <.lsb-story/>
        </div>
        """,
        :hello_world
      )

    assert template == """
           <div id="hello_world">
             <.lsb-story/>
           </div>
           """
  end

  test "story_template?/1" do
    assert story_template?("<div><.lsb-story/></div>")
    assert story_template?("<div><.lsb-story  /></div>")
    assert story_template?("<div><.lsb-story whatever /></div>")

    assert story_template?("""
           <div>
             <.lsb-story/>
           </div>
           """)

    refute story_template?("<div><story/></div>")
    refute story_template?("<div><.lsb-story-group/></div>")
  end

  test "story_group_template?/1" do
    assert story_group_template?("<div><.lsb-story-group/></div>")
    assert story_group_template?("<div><.lsb-story-group  /></div>")
    assert story_group_template?("<div><.lsb-story-group whatever /></div>")

    assert story_group_template?("""
           <div>
             <.lsb-story-group/>
           </div>
           """)

    refute story_group_template?("<div><story-group/></div>")
    refute story_group_template?("<div><.lsb-story/></div>")
  end

  test "replace_template_story/2" do
    heex =
      replace_template_story(
        """
        <div>
          <.lsb-story/>
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

  test "replace_template_story/2 with indentation" do
    heex =
      replace_template_story(
        """
        <div>
          <div>
            <.lsb-story/>
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

  test "replace_template_story_group/2" do
    heex =
      replace_template_story_group(
        """
        <div>
          <.lsb-story-group/>
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
    assert code_hidden?("<div lsb-code-hidden><.lsb-story/></div>")
    refute code_hidden?("<div><.lsb-story/></div>")
  end

  test "extract_placeholder_attributes/2" do
    assert extract_placeholder_attributes("<span/>") == ""
    assert extract_placeholder_attributes("<.lsb-story/>") == ""
    assert extract_placeholder_attributes("<.lsb-story-group/>") == ""
    assert extract_placeholder_attributes(~s|<.lsb-story foo="bar"/>|) == ~s|foo="bar"|

    assert extract_placeholder_attributes(~s|<.lsb-story-group form={f} foo="bar"/>|) ==
             ~s|form={f} foo="bar"|

    assert extract_placeholder_attributes(~s|<.lsb-story label="foo" status={true}/>|) ==
             ~s|label="foo" status={true}|
  end

  test "extract_placeholder_attributes/2 with inspection" do
    assert extract_placeholder_attributes("<span/>", {"topic", :story_id}) == ""
    assert extract_placeholder_attributes("<.lsb-story/>", {"topic", :story_id}) == ""
    assert extract_placeholder_attributes("<.lsb-story-group/>", {"topic", :story_id}) == ""

    assert extract_placeholder_attributes(~s|<.lsb-story foo={f}/>|, {"topic", :story_id}) ==
             ~s|foo={lsb_inspect("topic", :story_id, :foo, f)}|

    assert extract_placeholder_attributes(~s|<.lsb-story foo={"bar"}/>|, {"topic", :story_id}) ==
             ~s|foo={lsb_inspect("topic", :story_id, :foo, "bar")}|

    assert extract_placeholder_attributes(
             ~s|<.lsb-story-group form={f} foo="bar"/>|,
             {"topic", :story_id}
           ) ==
             ~s|form={lsb_inspect("topic", :story_id, :form, f)} foo={lsb_inspect("topic", :story_id, :foo, "bar")}|
  end
end
