-- Создаем универсальную версию (совместимую с LangChain и n8n)
create or replace function match_documents (
  query_embedding vector(3072),
  match_threshold float default 0.2, -- Порог схожести по умолчанию (можно менять)
  match_count int default null,
  filter jsonb default '{}'          -- Фильтр метаданных по умолчанию
)
returns table (
  id bigint,
  content text,
  metadata jsonb,
  similarity float
)
language plpgsql stable
as $$
begin
  return query
  select
    documents.id,
    documents.content,
    documents.metadata,
    1 - (documents.embedding <=> query_embedding) as similarity
  from documents
  -- Применяем фильтр по метаданным и порог схожести
  where documents.metadata @> filter 
    and 1 - (documents.embedding <=> query_embedding) > match_threshold
  order by documents.embedding <=> query_embedding
  limit match_count;
end;
$$;
