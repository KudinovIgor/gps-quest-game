-- 0) СТРАХОВКА: копируем то, что есть, в запасную таблицу (вдруг захочешь посмотреть)
create table if not exists public.quests_backup as select * from public.quests;

-- 1) сносим сломанные объекты
drop function if exists public.load_scenario(text);
drop table if exists public.quests;
drop table if exists public.scenarios;

-- 2) таблица сценариев
create table public.scenarios (
  id bigint generated always as identity primary key,
  slug text unique not null,
  title text not null,
  code text not null,
  is_public boolean not null default false
);
alter table public.scenarios enable row level security;
create policy scenarios_public_read on public.scenarios for select using (is_public);

-- 3) таблица точек
create table public.quests (
  id bigint generated always as identity primary key,
  scenario_slug text not null default 'main',
  title text not null,
  latitude float8 not null,
  longitude float8 not null,
  description text default '',
  answer text default '',
  hint text default '',
  comment text default '',
  sort_order integer not null default 0,
  kind text not null default 'main',
  radius_m integer not null default 40,
  constraint quests_scenario_fk foreign key (scenario_slug) references public.scenarios(slug)
);
alter table public.quests enable row level security;
create policy quests_read on public.quests for select using (
  exists (select 1 from public.scenarios s where s.slug = public.quests.scenario_slug and s.is_public)
);

-- 4) «дверь» по кодовому слову
create or replace function public.load_scenario(p_code text)
returns json language sql stable security definer as $$
  select json_build_object(
    'slug', s.slug, 'title', s.title,
    'quests', coalesce(json_agg(row_to_json(q)) filter (where q.id is not null), '[]'::json)
  )
  from public.scenarios s
  left join public.quests q on q.scenario_slug = s.slug
  where lower(trim(s.code)) = lower(trim(p_code))
  group by s.slug, s.title;
$$;
grant execute on function public.load_scenario(text) to anon, authenticated;

-- 5) сценарии (первый — с твоими точками, второй пример оставь на потом или удали)
insert into public.scenarios (slug,title,code,is_public) values
 ('main','Канищево и Приокский: военная слава','PRIOKSKY-2026',false);

-- 6) твои 20 точек
insert into public.quests (scenario_slug,title,latitude,longitude,description,answer,hint,comment,sort_order,kind) values
('main','Танковая аллея',54.6340,39.7280,'Сколько единиц боевой техники стоит в парке?','12','Танки, БМП, пушки, Грады...','Парк открыт в 1983 году. Под открытым небом: танк Т-72, БМП-1П, гаубица «Акация» и другие машины.',10,'main'),
('main','Памятник Братству',54.6345,39.7275,'В каком году установлен памятник?','1983','Смотри на табличку','Памятник установлен в честь 40-летия формирования Войска Польского в Рязани.',20,'main'),
('main','Торпеда',54.6320,39.7180,'Как называется торпеда, стоящая в парке?','53-65','Цифры на корпусе','Торпеда калибром 533 мм весит более 2 тонн. Принята на вооружение в 1965 году.',30,'main'),
('main','Якорь',54.6318,39.7175,'Сколько якорей стоит в парке?','3','Посчитай все','Здесь стоят якоря Холла, становой и другие.',40,'main'),
('main','Рубка подводной лодки',54.6322,39.7185,'Какой номер подводной лодки?','257','БС-257','Это рубка подводной лодки БС-257.',50,'main'),
('main','Гриб с глазами',54.6290,39.7350,'Кто этот гриб с глазами у пруда?','рыбак','У него удочка','Знаменитая рязанская скульптура: гриб с глазами — рыбак.',60,'main'),
('main','Сова на камне',54.6295,39.7345,'На чём сидит сова?','камень','Смотри под ноги','Каменная сова — символ мудрости.',70,'main'),
('main','Мостик через пруд',54.6300,39.7360,'Сколько фонарей на мостике?','4','Посчитай','Мостик через пруд «Родная заводь».',80,'main'),
('main','Школа №66',54.6280,39.7400,'Рядом с какой геометрической фигурой стоит школа?','круг','Клумба или площадка','Школа №66 — одна из старейших в районе.',90,'main'),
('main','Пожарная часть №5',54.6270,39.7380,'Сколько ворот у пожарной части?','3','Посчитай','Пожарная часть обслуживает Приокский район.',100,'main'),
('main','Детская поликлиника',54.6285,39.7370,'Сколько этажей у поликлиники?','3','Посчитай','Поликлиника на улице Бирюзова.',110,'main'),
('main','Памятник Аксёнову',54.6310,39.7320,'Сколько звёзд на бюсте?','2','Дважды Герой','Василий Филиппович Аксёнов — лётчик, дважды Герой Советского Союза.',120,'main'),
('main','Памятник воинам-интернационалистам',54.6305,39.7310,'Сколько букв в надписи «Афганистан»?','9','Посчитай','Памятник воинам, погибшим в Афганистане.',130,'main'),
('main','Самый старый дуб',54.6315,39.7290,'Сколько шагов от дуба до скамейки?','15','Посчитай шаги','Старейший дуб в Приокском лесопарке.',140,'main'),
('main','Аллея славы',54.6325,39.7300,'Сколько плит с именами героев?','20','Посчитай','Аллея памяти героев Великой Отечественной войны.',150,'main'),
('main','Граффити «Космос»',54.6275,39.7420,'Сколько планет нарисовано?','8','Посчитай','Яркое граффити на стене дома.',160,'main'),
('main','Арт-объект «Сердце»',54.6282,39.7390,'Из чего сделано сердце?','металл','Потрогай','Современная скульптура во дворе.',170,'main'),
('main','Стадион «Спартак»',54.6298,39.7365,'Сколько трибун на стадионе?','2','Посчитай','Главный стадион Приокского района.',180,'main'),
('main','Теннисные корты',54.6302,39.7375,'Сколько кортов огорожено сеткой?','3','Посчитай','Теннисные корты у школы.',190,'main'),
('main','Манчжурский орех',54.6328,39.7188,'Какое дерево даёт тень в центре парка?','орех','Не берёза и не дуб','Манчжурский орех сохранили при благоустройстве парка в 2025 году.',200,'main');

-- НОВЫЙ КВЕСТ
insert into public.scenarios (slug,title,code,is_public) values ('center','Центр: скобелевская тропа','SKOBELEV-70-BATTLES',false);
-- и точки с scenario_slug='center'
