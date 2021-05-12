module WithPgLock
  ##
  # Lock PG table, reload model and execute callback if
  # criterion is met
  #
  def with_pg_lock(callback, criterion)
    # Some notes:
    #
    # * nowait is a postgre specific option and may not work with other databases
    # * nowait will raise an exception if the lock can not be acquired
    # * we are using a double check lock pattern to reduce lock acquisition
    with_lock('for update nowait') do
      reload
      callback.call if criterion.call
    end if criterion.call
  rescue
    nil
  end
end
