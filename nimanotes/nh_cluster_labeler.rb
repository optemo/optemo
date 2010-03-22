# NH cluster labelers are cluster labeling algorithms that are not
# aware of the cluster hierarchy. Word counting is performed to
# compute the labels for the leaf clusters. Word counts for child
# clusters are combined to form word counts for non-leaf
# clusters. These word counts for non-leaf clusters are then used to
# compute non-leaf cluster labels.
require 'stemmer'
require 'sqlite3'

$DEBUG = 1
def assert
  raise "Assertation failed!" unless yield if $DEBUG
end

module NHClusterLabeler
  # Computes stemmed word counts and returns it as a hash table.
  def compute_word_counts(cluster)
    clustersize = cluster.cluster_size

    if clustersize > 1
      clusterchildren = get_cluster_children(cluster)
      clusterchildren.each do |c|
        compute_word_counts(c)
      end

      clusterchildren.map do |c|
        sum_word_counts(cluster, c)
      end
    else
      compute_word_counts_for_singleton(cluster)
    end
  end

  def compute_word_counts_for_singleton(singleton)
    assert { singleton.cluster_size == 1 }
    item_ids = get_item_ids_in_cluster(singleton)
    assert { item_ids.count == 1}

    get_reviews_for_item(item_ids.first).map do |r|
      content = r.content
    end
  end

  # Combines two word counts by summing together the entries that they
  # have in common.
  def sum_word_counts(wc0, wc1)
  end

  def compute_cluster_labels(cluster, @scoring_fn)
    compute_word_counts(cluster)
    score_cluster_labels(cluster, @scoring_fn)
  end

  # scoring_fn uses the computed word counts for a cluster to score
  # all the words present in that cluster's documents and returns a
  # hash of word => score. The wordscore hash is sorted and returned.
  def score_cluster_labels(cluster, @scoring_fn)
    wordscores = @scoring_fn(cluster)
    wordscores.sort{ |a, b| a[1] <=> b[1] }
  end
end
