-- Minimal SQL-format schema dump.
-- Deliberately in structure.sql (not schema.rb) so eval 2 tests whether the agent
-- checks the repo's schema format before reporting missing indexes.
--
-- INDEXED (a missing-index finding on these is a FALSE POSITIVE):
--   products.status, products.category_id, categories.slug
-- NOT INDEXED (a genuine finding):
--   orders.user_id, reviews.product_id

CREATE TABLE public.categories (
    id bigint NOT NULL,
    name character varying NOT NULL,
    slug character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);

CREATE TABLE public.products (
    id bigint NOT NULL,
    category_id bigint NOT NULL,
    name character varying NOT NULL,
    status character varying DEFAULT 'draft'::character varying NOT NULL,
    price_cents integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);

CREATE TABLE public.orders (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    total_cents integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);

CREATE TABLE public.reviews (
    id bigint NOT NULL,
    product_id bigint NOT NULL,
    rating integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);

ALTER TABLE ONLY public.categories ADD CONSTRAINT categories_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.products ADD CONSTRAINT products_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.orders ADD CONSTRAINT orders_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.reviews ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);

CREATE UNIQUE INDEX index_categories_on_slug ON public.categories USING btree (slug);
CREATE INDEX index_products_on_status ON public.products USING btree (status);
CREATE INDEX index_products_on_category_id ON public.products USING btree (category_id);

-- Note: no index on orders.user_id or reviews.product_id.
