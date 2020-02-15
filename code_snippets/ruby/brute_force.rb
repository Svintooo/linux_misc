#!/usr/bin/env ruby

chars = %w(
  A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
  a b c d e f g h i j k l m n o p q r s t u v w x y z
  0 1 2 3 4 5 6 7 8 9
  _ . /
) << "\n"

length=0

loop do
  length += 1
  array = Array.new(length){|i| 0 }

  loop do
    puts array.collect{|n| chars[n] }.join("")

    finished = false
    array[0] += 1

    array.each_index do |i|
      next unless array[i] >= chars.length

      if i == array.length - 1
        finished = true
        break
      end

      array[i] = 0
      array[i+1] += 1
    end

    break if finished
    sleep 0.1
  end
end
