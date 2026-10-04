describe 'HyperComponent', type: :system do
  describe 'track_changes' do
    before(:each) do
      page_eval do
        class ComponentWithTrackedChanges < HyperComponent

          param :param1
          param :param2
          param :param3
          param :param4
          param :reload

          track_changes :param1, :param2, [:param3, :a, :b], [:param4, :a, :b], :wrong

          render do
            DIV(id: 'param1-changed') do
              param1_changed?.to_s
            end
            DIV(id: 'param2-changed') do
              param2_changed?.to_s
            end
            DIV(id: 'param3-a-b-changed') do
              param3_a_b_changed?.to_s
            end
            DIV(id: 'param4-a-b-changed') do
              param4_a_b_changed?.to_s
            end
          end
        end

        class ParentComponentForTrackChanges < HyperComponent

          before_mount do
            @param1 = 1
            @param2 = 1
            @param3 = {a: {b: 1}}
            @param4 = OpenStruct.new(a: OpenStruct.new(b: 1))
            @reload = 1
          end

          render do
            ComponentWithTrackedChanges(
              param1: @param1,
              param2: @param2,
              param3: @param3,
              param4: @param4,
              reload: @reload,
            )
            BUTTON { 'param1' }.on(:click) do
              `console.error("click param1")`
              @param1 += 1
              mutate
            end
            BUTTON { 'param2' }.on(:click) do
              `console.error("click param2")`
              @param2 += 1
              mutate
            end
            BUTTON { 'param3' }.on(:click) do
              `console.error("click param3")`;
              @param3[:a][:b] += 1
              @reload += 1 # otherwise ComponentWithTrackedChanges is not rerenderd due to shallow compare
              mutate
            end
            BUTTON { 'param4' }.on(:click) do
              `console.error("click param4")`;
              @param4.a.b += 1;
              @reload += 1 # otherwise ComponentWithTrackedChanges is not rerenderd due to shallowCompare
              mutate
            end
            BUTTON { 'rerender' }.on(:click) do
              `console.error("click rerender")`
              @reload += 1
              mutate
            end
          end

        end
      end

      mount do
        ParentComponentForTrackChanges()
      end
    end

    it 'track_changes should define _changed? methods' do
      expect(
        page_eval { ComponentWithTrackedChanges.method_defined?(:param1_changed?) }
      ).to eq true
      expect(
        page_eval { ComponentWithTrackedChanges.method_defined?(:param2_changed?) }
      ).to eq true
      expect(
        page_eval { ComponentWithTrackedChanges.method_defined?(:param3_a_b_changed?) }
      ).to eq true
      expect(
        page_eval { ComponentWithTrackedChanges.method_defined?(:param4_a_b_changed?) }
      ).to eq true
    end

    it 'should be considered as changed after mount' do
      expect(page).to have_css('#param1-changed', text: 'true')
      expect(page).to have_css('#param2-changed', text: 'true')
      expect(page).to have_css('#param3-a-b-changed', text: 'true')
      expect(page).to have_css('#param4-a-b-changed', text: 'true')
    end

    it 'should detect that tracked params are not changed after a rerender' do
      expect(page).to have_css('#param1-changed', text: 'true')
      expect(page).to have_css('#param2-changed', text: 'true')
      expect(page).to have_css('#param3-a-b-changed', text: 'true')
      expect(page).to have_css('#param4-a-b-changed', text: 'true')
      click_button('rerender')
      expect(page).to have_css('#param1-changed', text: 'false')
      expect(page).to have_css('#param2-changed', text: 'false')
      expect(page).to have_css('#param3-a-b-changed', text: 'false')
      expect(page).to have_css('#param4-a-b-changed', text: 'false')
    end

    it 'should detect only tracked params that are changed' do
      click_button('param1')
      expect(page).to have_css('#param1-changed', text: 'true')
      expect(page).to have_css('#param2-changed', text: 'false')
      expect(page).to have_css('#param3-a-b-changed', text: 'false')
      expect(page).to have_css('#param4-a-b-changed', text: 'false')
      click_button('param2')
      expect(page).to have_css('#param1-changed', text: 'false')
      expect(page).to have_css('#param2-changed', text: 'true')
      expect(page).to have_css('#param3-a-b-changed', text: 'false')
      expect(page).to have_css('#param4-a-b-changed', text: 'false')
      click_button('param3')
      expect(page).to have_css('#param1-changed', text: 'false')
      expect(page).to have_css('#param2-changed', text: 'false')
      expect(page).to have_css('#param3-a-b-changed', text: 'true')
      expect(page).to have_css('#param4-a-b-changed', text: 'false')
      click_button('param4')
      expect(page).to have_css('#param1-changed', text: 'false')
      expect(page).to have_css('#param2-changed', text: 'false')
      expect(page).to have_css('#param3-a-b-changed', text: 'false')
      expect(page).to have_css('#param4-a-b-changed', text: 'true')
    end
  end

  describe '#on()' do
    before(:each) do
      page_eval do
        class ComponentWithProc < HyperComponent
          param :btn_text
          fires :change

          render() do
            BUTTON do
              btn_text
            end.on(:click) do
              change!
            end
          end
        end

        class ParentComponentForComponentWithProc < HyperComponent

          before_mount do
            @count = 0
            $result = nil
          end

          render do
            @count += 1
            a = @count
            ComponentWithProc(btn_text: "button").on(:change) do
              $result = a
              mutate
            end
          end

        end
      end

      mount do
        ParentComponentForComponentWithProc()
      end
    end

    it 'correct procs should be used' do
      click_button('button')
      expect(page_eval { $result }).to eq 1

      click_button('button')
      expect(page_eval { $result }).to eq 2
    end

  end

end
