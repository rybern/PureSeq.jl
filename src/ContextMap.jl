using DataStructures
using Compat

import Base: eof, close, position
export ContextMap, close, value, eof, advance!

type ContextMap
    reader
    contextBefore::Int64
    contextAfter::Int64
    position::Int64
    @compat posQueue::Deque{Tuple{Int64,Float64}}
    value::Float64
end

function ContextMap(reader, contextBefore::Int64, contextAfter::Int64)
    cm = ContextMap(reader, contextBefore, contextAfter, 0, Deque{Tuple{Int64,Float64}}(), 0.0)

    advance!(cm)
    cm
end
close(cm::ContextMap) = close(cm.reader)
value(cm::ContextMap) = cm.value
position(cm::ContextMap) = cm.position
eof(cm::ContextMap) = cm.position < 0

function advance!(cm::ContextMap)
    cm.position += 1

    # remove old positions that fell outside the sliding window
    while length(cm.posQueue) > 0 && front(cm.posQueue)[1] < cm.position-cm.contextBefore
        cm.value -= front(cm.posQueue)[2]
        shift!(cm.posQueue)
    end

    # skip ahead to the next spot we have data if our queue is empty
    if length(cm.posQueue) == 0
        cm.position = position(cm.reader)-cm.contextBefore
    end

    # add new positions in the sliding window
    while !eof(cm.reader) && position(cm.reader) <= cm.position+cm.contextAfter
        v = value(cm.reader)
        cm.value += v
        push!(cm.posQueue, (position(cm.reader),v))
        advance!(cm.reader)
    end
end
