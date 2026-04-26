require 'colorize'
class DiffCalc
  attr_reader :mem, :cnt, :old_s, :new_s

  def initialize
    @mem = {}
    @cnt = 0
  end

  def compute_diff(old_arr, new_arr)
    @mem = {}
    @old_s = old_arr
    @new_s = new_arr
    differencing(0, 0)
  end

  def differencing(i1 = 0, i2 = 0)
    cached = @mem[[i1, i2]]
    return cached if cached

    if i1 >= @old_s.length && i2 >= @new_s.length
      result = { diff_cnt: 0, insertions: 0, deletions: 0, action: :done }
      @mem[[i1, i2]] = result
      return result
    end

    if i1 >= @old_s.length
      result = { diff_cnt: @new_s.length - i2, insertions: @new_s.length - i2, deletions: 0, action: :insert }
      @mem[[i1, i2]] = result
      differencing(i1, i2 + 1) if i2 < @new_s.length
      return result
    end

    if i2 >= @new_s.length
      result = { diff_cnt: @old_s.length - i1, insertions: 0, deletions: @old_s.length - i1, action: :delete }
      @mem[[i1, i2]] = result
      differencing(i1 + 1, i2) if i1 < @old_s.length
      return result
    end

    if @old_s[i1] == @new_s[i2]
      result = differencing(i1 + 1, i2 + 1)
      result = { diff_cnt: result[:diff_cnt], insertions: result[:insertions], deletions: result[:deletions],
                 action: :keep }
      @mem[[i1, i2]] = result
      return result
    end

    del = differencing(i1 + 1, i2)
    add = differencing(i1, i2 + 1)

    del_cost = del[:diff_cnt] + 1
    add_cost = add[:diff_cnt] + 1

    result = if del_cost <= add_cost
               { diff_cnt: del_cost, insertions: del[:insertions], deletions: del[:deletions] + 1, action: :delete }
             else
               { diff_cnt: add_cost, insertions: add[:insertions] + 1, deletions: add[:deletions], action: :insert }
             end

    @mem[[i1, i2]] = result
    result
  end

  def build_sequences
    i1 = 0
    i2 = 0
    insertion_seq = {}
    deletion_seq = {}

    while i1 < @old_s.length || i2 < @new_s.length
      action = @mem[[i1, i2]][:action]

      case action
      when :done
        break
      when :keep
        i1 += 1
        i2 += 1
      when :delete
        deletion_seq[i2] ||= []
        deletion_seq[i2].push({ old_index: i1, ma_type: 'bs' })
        i1 += 1
      when :insert
        insertion_seq[i2] = { value: @new_s[i2], old_index: i1 }
        i2 += 1
      end
    end

    result = @mem[[0, 0]]
    {
      insertion_seq: insertion_seq,
      deletion_seq: deletion_seq,
      insertions: result[:insertions],
      deletions: result[:deletions],
      diff_cnt: result[:diff_cnt]
    }
  end

  def print_diff(file_a, file_b)
    compute_diff(file_a, file_b)
    diff = build_sequences
    insertions, deletions, insertion_seq, deletion_seq = diff.values_at(:insertions, :deletions, :insertion_seq,
                                                                        :deletion_seq)
    # printing diff
    puts "Diff: (+): #{insertions}    (-): #{deletions}"

    # sorting by keys
    insertion_seq = insertion_seq.sort.to_h
    insertion_seq_keys = insertion_seq.keys

    deletion_seq = deletion_seq.sort.to_h
    deletion_seq_keys = deletion_seq.keys

    # index (old or new)
    # value (styled text to be printed)
    # type (-1 => deletion, 0 => insertion, 1 => not changed)
    edit_list = []

    # Getting a list of all the changes
    insertion_poniter = 0
    deletion_pointer = 0
    while insertion_poniter < insertions || deletion_pointer < deletion_seq_keys.length
      is_insertion = if insertion_poniter >= insertions
                       false
                     elsif deletion_pointer >= deletion_seq_keys.length
                       true
                     else
                       insertion_seq_keys[insertion_poniter] < deletion_seq_keys[deletion_pointer]
                     end
      index = is_insertion ? insertion_seq_keys[insertion_poniter] : deletion_seq_keys[deletion_pointer]
      if is_insertion
        edit_list.push({ index: index, value: "#{insertion_seq[index][:value]}", type: 0,
                         old_index: insertion_seq[index][:old_index] })
        insertion_poniter += 1
      else
        deletion_seq[index] = deletion_seq[index].sort_by { |del| del[:old_index] }
        deletion_seq[index].each do |del|
          old_index = del[:old_index]
          edit_list.push({ index: index, value: "#{file_a[old_index]}", type: -1,
                           old_index: old_index })
        end
        deletion_pointer += 1
      end

    end

    max_space_diff = 3
    print_queue = {}
    # Getting all the lines to print (including context ones)
    edit_list.each_with_index do |order, _i|
      (order[:index] - max_space_diff..order[:index] + max_space_diff).each do |j|
        next unless j >= 0 && j < file_b.length

        line = order[:index] == j ? order : { index: j, value: file_b[j], type: 1, old_index: j }
        print_queue[j] ||= []
        print_queue[j].push(line) unless line[:type] == 1 && print_queue[j].length.positive?
      end
    end

    print_queue = print_queue.sort.to_h
    print_queue_keys = print_queue.keys
    printed = {}

    # Stylizing & printing lines
    def print_line(line)
      sign = if line[:type] == -1
               '-'
             else
               line[:type] == 0 ? '+' : ''
             end

      index = if line[:type] == -1
                line[:old_index]
              else
                line[:index]
              end
      print_text = "#{index} #{sign}#{line[:value]}"
      if line[:type] == -1
        print_text = print_text.red
      elsif line[:type] == 0
        print_text = print_text.green
      end
      puts print_text
    end

    # Printing all the lines
    print_queue.each_with_index do |(index, lines), queue_i|
      lines = lines.sort_by { |line| line[:type] }
      is_changed = false
      lines.each do |line, _i|
        next if printed[[index, line[:type]]] == 1

        print_line(line) unless is_changed == true && line[:type] == 1
        is_changed = true

        next unless line[:type] == -1

        j = queue_i + 1

        define_singleton_method :is_deletion? do
          return false if j >= print_queue_keys.length

          print_queue[print_queue_keys[j]]&.any? { |x| x[:type] == -1 }
        end

        while is_deletion?
          q_i = print_queue_keys[j]
          cur_line = print_queue[q_i].find { |x| x[:type] == -1 }
          cur_line ||= print_queue[q_i].find { |x| x[:type] == 1 }
          print_line(cur_line)
          printed[[q_i, cur_line[:type]]] = 1
          j += 1
        end
      end
    end
  end
end
