package org.kolonitsky.coursera.nlp;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.*;

/**
 * @author Alex.Kolonitsky
 */
public class DataManager {

    public static class Type {
        public static ArrayList<Type> values = new ArrayList<Type>();

        public static Type WORD_PROBABILIST = create("WORDTAG");
        public static Type WORD_SEQ_1 = create("1-GRAM");
        public static Type WORD_SEQ_2 = create("2-GRAM");
        public static Type WORD_SEQ_3 = create("3-GRAM");

        private static Type create(String str) {
            Type type = new Type(str);
            values.add(type);

            return type;
        }

        public static Type valueOf(String str) {
            for (Type value : values) {
                if (value.name.equals(str)) {
                    return value;
                }
            }

            return null;
        }

        private final String name;


        private Type(String name) {
            this.name = name;
        }

        @Override
        public String toString() {
            return name;
        }
    }

    private static final Logger LOG = LoggerFactory.getLogger(DataManager.class);

    public Map<Type, List<WordCount>> data = new HashMap<Type, List<WordCount>>();
    public Map<String, Integer> counts = new HashMap<String, Integer>();


    public void load(File file) {
        try {
            BufferedReader br = new BufferedReader(new FileReader(file));
            String line = br.readLine();
            while (line != null) {
                loadLine(line);
                line = br.readLine();
            }
            br.close();
        } catch (IOException e) {
            LOG.error(e.getMessage(), e);
        }


    }

    private void loadLine(String line) {
        Scanner s = new Scanner(line).useDelimiter(" ");

        int count = s.nextInt();
        Type type = Type.valueOf(s.next());
        List<String> text = new ArrayList<String>(5);
        while (s.hasNext()) {
            text.add(s.next());
        }

        WordCount wordCount = new WordCount(count, text.toArray(new String[text.size()]));
        put(type, wordCount);
        counts.put(wordCount.getText(), count);
        s.close();
    }

    public void put(Type type, WordCount wordCount) {
        get(type).add(wordCount);
    }

    public List<WordCount> get(Type type) {
        List<WordCount> wordCounts = data.get(type);
        if (wordCounts == null) {
            wordCounts = new ArrayList<WordCount>();
            data.put(type, wordCounts);
        }
        return wordCounts;
    }

    public double e(String word, String tag) {
        Integer count = counts.get(tag + " " + word);
        if (count == null) {
            count = counts.get(tag + " " + ReplaceRareWords.RARE_WORD);
        }

        return ((double) count) / (double) counts.get(tag);
    }

    public String argMaxE(String word, String ... tags) {
        double max = -1;
        String maxTag = null;

        for (String tag : tags) {
            double e = e(word, tag);
            if (e > max) {
                max = e;
                maxTag = tag;
            }
        }

        return maxTag;
    }
}
