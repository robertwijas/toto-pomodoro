module Toto::Pomodoro
  
  @@label_synonyms = []
  
  class << self
    attr_accessor :label_synonyms
  end
  
  def self.standard_label label
    label_synonyms.each do
      |synonyms|
      return synonyms.first if synonyms.find_index(label)
    end
    
    return label
  end
  
  def self.standard_month_date date
    date - date.day + 1 
  end

  def self.pomodoro_count articles
    articles.map {|a| a.pomodoros.count}.inject{|sum,x| sum + x}
  end

  def self.daily_average articles
    days = []
    pomodoro_count = 0
    
    articles.each do
      |a|
      pomodoro_count += a.pomodoros.count
      if a.pomodoros.count
        days << a[:date]
      end
    end
    
    days.uniq!
    
    days.empty? ? 0 : pomodoro_count / days.count.to_f
  end

  def self.monthly_stats_data articles
    months = {}
    labels = []

    articles.each do
      |a|
      date = standard_month_date a[:date]
      month_data = months[date] || {}

      a.pomodoros.each do
        |label|
        label = standard_label label
        month_data[label] = month_data[label].to_i + 1
        labels << label
      end

      months[date] = month_data
    end

    labels.uniq!
    labels.sort!

    months_array = months.keys.sort
    data = []

    months_array.each do
      |m|
      labels.each do
        |l|
        # choose data object for update
        d = data.select {|x| x['name'].eql?(l)}.first

        if d.nil?
          d = {'name' => l, 'data' => []}
          data << d
        end

        d['data'] << (months[m][l].nil? ? 0 : months[m][l])
      end
    end

    return months_array, data
  end

  def self.article_count_stats_data articles
    data = articles.reverse.collect do
      |a|
      {:y => a.pomodoros.count, :url => a.url, :title => a.title, :x => (Time.parse(a[:date].to_s).to_i * 1000)}
    end

    return data
  end

  def self.label_pomodoros articles
    data = {}
    articles.each do
      |a|
      a.pomodoros.each do
        |l|
        l = standard_label l
        data[l] = data[l].to_i + 1
      end
    end

    return data
  end

  def self.labels_stats_data articles
    data = label_pomodoros articles
    tags = data.keys.sort

    pomodoros = []
    tags.each do
      |t|
      pomodoros << data[t]
    end

    return tags, pomodoros
  end
  
end

class Toto::Article
  
  def pomodoros
    self[:pomodoros] ? self[:pomodoros].to_s.split : []
  end

end
